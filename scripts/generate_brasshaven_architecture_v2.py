#!/usr/bin/env python3
# Run with: blender --background --python scripts/generate_brasshaven_architecture.py
import bpy, math, json, struct, zlib, binascii
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'original' / 'brasshaven_architecture_v2'
OUT.mkdir(parents=True, exist_ok=True)

PALETTE = {
    'brick': (0.25,0.21,0.17,1),
    'brick_light': (0.36,0.29,0.22,1),
    'iron': (0.20,0.21,0.21,1),
    'iron_light': (0.34,0.34,0.32,1),
    'brass': (0.58,0.34,0.12,1),
    'copper': (0.48,0.23,0.11,1),
    'concrete': (0.31,0.30,0.28,1),
    'glass': (0.16,0.48,0.59,1),
    'hot': (0.96,0.22,0.05,1),
    'blue': (0.18,0.58,0.86,1),
    'cloth': (0.42,0.24,0.15,1),
    'dark': (0.11,0.11,0.10,1),
}
KEYS=list(PALETTE.keys()); GRID=4; CELL=16; ATLAS=OUT/'brass_v2_palette.png'

def write_png():
    w=GRID*CELL; h=GRID*CELL; rows=[]
    for y in range(h):
        row=bytearray([0]); cy=y//CELL
        for x in range(w):
            cx=x//CELL; i=cy*GRID+cx
            rgb=[255,0,255] if i>=len(KEYS) else [round(c*255) for c in PALETTE[KEYS[i]][:3]]
            row.extend(rgb)
        rows.append(bytes(row))
    raw=b''.join(rows)
    def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',binascii.crc32(t+d)&0xffffffff)
    ATLAS.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))

def atlas_material():
    write_png(); img=bpy.data.images.load(str(ATLAS),check_existing=True)
    m=bpy.data.materials.get('EL_BrasshavenPaletteV2') or bpy.data.materials.new('EL_BrasshavenPaletteV2'); m.use_nodes=True
    nodes=m.node_tree.nodes; links=m.node_tree.links; bsdf=nodes.get('Principled BSDF')
    tex=nodes.get('EL_Palette') or nodes.new('ShaderNodeTexImage'); tex.name='EL_Palette'; tex.image=img; tex.interpolation='Closest'
    links.new(tex.outputs['Color'],bsdf.inputs['Base Color']); bsdf.inputs['Roughness'].default_value=0.62
    return m

def mat(name,rgba,metallic=0,rough=.65,emission=False):
    m=bpy.data.materials.get('EL_'+name)
    if m: return m
    m=bpy.data.materials.new('EL_'+name); m.diffuse_color=rgba; m.use_nodes=True
    b=m.node_tree.nodes.get('Principled BSDF'); b.inputs['Base Color'].default_value=rgba; b.inputs['Metallic'].default_value=metallic; b.inputs['Roughness'].default_value=rough
    if emission:
        if 'Emission Color' in b.inputs: b.inputs['Emission Color'].default_value=rgba; b.inputs['Emission Strength'].default_value=2
        elif 'Emission' in b.inputs: b.inputs['Emission'].default_value=rgba
    return m

def materials(): return {k:mat(k,v,.65 if k in ('iron','iron_light','brass','copper') else 0,.42 if k in ('iron','iron_light','brass','copper') else .7,k in ('hot','blue')) for k,v in PALETTE.items()}
M={}

def clear(): bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def box(name,loc,dims,m,bevel=.08,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot); o=bpy.context.object; o.name=name; o.dimensions=dims; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('edge','BEVEL'); mod.width=bevel; mod.segments=1; bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.materials.append(M[m]); return o

def cyl(name,loc,radius,depth,m,vertices=12,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc,rotation=rot); o=bpy.context.object; o.name=name; o.data.materials.append(M[m]); return o

def pipe(name,a,b,r=.65,m='iron',verts=10):
    from mathutils import Vector
    a=Vector(a); b=Vector(b); d=b-a; mid=(a+b)/2
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d.length,location=mid)
    o=bpy.context.object; o.name=name; o.rotation_mode='QUATERNION'; o.rotation_quaternion=d.to_track_quat('Z','Y'); o.data.materials.append(M[m]); return o

def apply_atlas(obj):
    slots=[slot.material.name if slot.material else '' for slot in obj.material_slots]
    uv=obj.data.uv_layers.get('UVMap') or obj.data.uv_layers.new(name='UVMap')
    for poly in obj.data.polygons:
        n=slots[poly.material_index] if poly.material_index<len(slots) else ''
        key='concrete'
        for k in KEYS:
            if n.lower()==('el_'+k).lower() or n.lower().endswith('_'+k.lower()): key=k; break
        i=KEYS.index(key); u=(i%GRID+.5)/GRID; v=1-(i//GRID+.5)/GRID
        for li in poly.loop_indices: uv.data[li].uv=(u,v)
        poly.material_index=0
    obj.data.materials.clear(); obj.data.materials.append(atlas_material())

def export(name):
    bpy.ops.object.select_all(action='DESELECT'); objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in objs:o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]; bpy.ops.object.join(); obj=bpy.context.object; obj.name=name; apply_atlas(obj)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    path=OUT/(name+'.glb'); bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_apply=True,export_materials='EXPORT')
    tris=sum(len(p.vertices)-2 for p in obj.data.polygons)
    return {'file':str(path.relative_to(ROOT)),'triangles':tris,'vertices':len(obj.data.vertices),'materials':len(obj.data.materials)}

def windows_front(width, y, z=5.2,count=3):
    for i in range(count):
        x=(-width*.3)+(width*.6)*(i/(count-1) if count>1 else .5)
        box('Window',(x,y,z),(2.6,.18,3.0),'glass',.03)
        box('WindowFrame',(x,y-.03,z),(3.0,.28,3.4),'iron',.03)
        box('WindowPane',(x,y-.20,z),(2.4,.12,2.8),'glass',.02)


def foundry_admin():
    # Civic-industrial headquarters: split masonry wings, raised command bridge, clock/gear tower.
    box('Base',(0,0,.7),(40,29,1.4),'concrete',.16)
    box('WestWing',(-10,2,6.5),(18,21,11),'brick_light',.14)
    box('EastWing',(10,3,5.6),(16,17,9),'brick',.12)
    box('Bridge',(0,-1,11.5),(14,10,6),'iron_light',.10)
    box('WestRoof',(-10,2,12.4),(20,23,1.1),'iron',.06,rot=(0,math.radians(4),0))
    box('EastRoof',(10,3,10.6),(18,19,1.0),'iron',.06,rot=(0,math.radians(-6),0))
    box('CommandTower',(0,6,13),(9,9,20),'brick',.13)
    cyl('ClockGear',(0,-4.6,15),3.2,.5,'brass',14,rot=(math.radians(90),0,0))
    cyl('ClockCore',(0,-4.9,15),1.3,.6,'hot',12,rot=(math.radians(90),0,0))
    for x in (-14,14):
        pipe('Stack',(x,8,11),(x,8,24),.9,'dark'); cyl('StackCap',(x,8,24.5),1.35,1.0,'brass',10)
    box('EntryStair',(0,-14,1.2),(12,5,1.4),'concrete',.06)
    box('EntryCanopy',(0,-13,7.1),(14,6,.8),'brass',.05)
    for x in (-5.2,5.2): box('EntryPost',(x,-14.5,3.7),(.6,.6,6.5),'iron',.03)
    windows_front(32,-10.6,6.4,4)
    return export('BrassFoundryAdminHallV2')

def machinist():
    # Long open shop with sawtooth roof, side crane and machine bay.
    box('Base',(0,0,.65),(44,28,1.3),'concrete',.15)
    box('ShopBody',(-5,2,5.8),(27,22,9.5),'brick',.12)
    for x,tilt in [(-14,12),(-5,-12),(4,12)]:
        box('SawRoof',(x,2,11.6),(10,24,1),'iron',.04,rot=(0,math.radians(tilt),0))
    box('MachineBay',(15,3,5.2),(13,16,8.3),'iron_light',.08)
    box('OpenApron',(13,-10,1.1),(22,8,.7),'iron_light',.04)
    box('CraneMast',(21,-6,9),(.8,.8,17),'iron',.03)
    pipe('CraneArm',(21,-6,17),(8,-14,17),.55,'brass')
    cyl('CraneWheel',(11,-12,16.5),1.5,.45,'iron',12,rot=(math.radians(90),0,0))
    pipe('VentA',(-12,10,10),(-12,10,19),.75,'copper')
    pipe('VentB',(-2,10,10),(-2,10,16),.6,'copper')
    windows_front(27,-9.15,5.7,3)
    return export('BrassMachinistWorkshopV2')

def smelter():
    # Furnace cathedral with crucible tower and paired exhaust stacks.
    box('Base',(0,0,.7),(38,31,1.4),'concrete',.15)
    box('FurnaceNave',(-5,1,8),(24,23,14),'brick',.14)
    box('FurnaceRoof',(-5,1,15.2),(27,26,1.2),'iron',.06)
    box('CrucibleTower',(13,3,10),(12,15,18),'iron_light',.12)
    cyl('Crucible',(13,3,9),4.3,12,'dark',14)
    cyl('CrucibleBand',(13,3,5),4.6,.65,'brass',14)
    cyl('CrucibleBand',(13,3,13),4.6,.65,'brass',14)
    box('FurnaceMouth',(2,-10.7,5.2),(7,.4,5.2),'hot',.03)
    box('HeatLintel',(2,-11,8.3),(9,.7,1.1),'brass',.04)
    for x in (-11,-2):
        pipe('Stack',(x,8,13),(x,8,30),1.2,'dark'); cyl('StackCap',(x,8,30.5),1.8,1.2,'iron',12)
    pipe('FeedMain',(8,8,12),(18,8,12),.8,'copper')
    pipe('FeedDrop',(18,8,12),(18,8,5),.8,'copper')
    return export('BrassSmelterHouseV2')

def boiler():
    # Tank farm + narrow operator house + overhead pipe bridge.
    box('Base',(0,0,.6),(38,28,1.2),'concrete',.14)
    box('ControlHouse',(-11,-1,5.5),(12,21,9),'brick_light',.10)
    box('ControlRoof',(-11,-1,10.5),(14,23,1),'iron',.05)
    for x,z in [(1,7),(10,8.5)]:
        cyl('Boiler',(x,1,z),4.5,12 if x==1 else 15,'iron',16)
        cyl('Band',(x,1,z-3),4.8,.6,'brass',16); cyl('Band',(x,1,z+3),4.8,.6,'brass',16)
    box('PipeBridge',(4,1,15.5),(22,4,1.1),'iron_light',.04)
    for x in (-6,14): box('BridgeLeg',(x,1,8),(.7,.7,14),'iron',.03)
    pipe('Header',(-5,1,16),(15,1,16),.7,'copper')
    pipe('Stack',(10,1,16),(10,1,26),1.0,'dark')
    return export('BrassBoilerStationV2')

def barracks():
    # Two-level worker block with balcony, stair tower and mess annex.
    box('Base',(0,0,.65),(42,28,1.3),'concrete',.14)
    box('MainBlock',(-6,1,8),(23,22,14),'brick_light',.12)
    box('MainRoof',(-6,1,15.5),(25,24,1.0),'iron',.05)
    box('MessAnnex',(13,4,5.2),(15,15,8.2),'brick',.10)
    box('MessRoof',(13,4,9.8),(17,17,1),'iron',.05)
    box('Balcony',(-6,-11.5,9),(23,3,.6),'iron_light',.04)
    for x in (-15,-6,3): box('BalconyPost',(x,-11.5,4.8),(.5,.5,8),'iron',.03)
    box('StairTower',(10,-8,8),(7,7,14),'iron_light',.10)
    for z in (4.5,8.5,12.5): box('StairLanding',(10,-11.8,z),(7,3,.5),'brass',.03)
    windows_front(23,-10.15,6.5,3)
    return export('BrassWorkerBarracksV2')

def loading():
    # Rail-facing warehouse with deep canopy and traveling gantry crane.
    box('Base',(0,0,.6),(48,30,1.2),'concrete',.14)
    box('Warehouse',(-10,2,6),(22,22,10),'brick',.12)
    box('WarehouseRoof',(-10,2,11.6),(24,24,1),'iron',.05)
    box('RailDeck',(12,-2,1.25),(24,24,.8),'iron_light',.04)
    box('Canopy',(12,-2,10),(25,25,.8),'brass',.05)
    for x in (2,12,22):
        box('CanopyPost',(x,-12,5.2),(.6,.6,9),'iron',.03)
        box('CanopyPost',(x,8,5.2),(.6,.6,9),'iron',.03)
    box('CraneRailA',(0,-9,15),(39,.5,.6),'iron',.02)
    box('CraneRailB',(0,6,15),(39,.5,.6),'iron',.02)
    box('CraneBridge',(13,-1.5,15),(1,16,1),'brass',.03)
    pipe('HookLine',(13,-1.5,14),(13,-1.5,7),.18,'dark')
    cyl('Hook',(13,-1.5,6.3),.55,1.2,'iron',8)
    return export('BrassLoadingDepotV2')

def gatehouse():
    # Fortified industrial portal with offset control block and pressure wheel centerpiece.
    box('LeftPylon',(-15,0,11),(10,13,22),'brick',.13)
    box('RightPylon',(15,0,11),(10,13,22),'brick',.13)
    box('Overbridge',(0,0,19),(21,11,7),'iron_light',.10)
    box('TopTruss',(0,0,24),(34,14,1.2),'brass',.05)
    box('ControlBlock',(24,4,7),(9,11,12),'brick_light',.11)
    box('ControlRoof',(24,4,13.5),(11,13,1),'iron',.05)
    cyl('GateWheel',(0,-6.0,15),4.0,.7,'brass',16,rot=(math.radians(90),0,0))
    cyl('GateHub',(0,-6.4,15),1.3,.8,'hot',12,rot=(math.radians(90),0,0))
    box('WarningBeam',(0,-5.5,7),(18,.5,1),'hot',.02)
    for x in (-15,15): pipe('Exhaust',(x,4,20),(x,4,29),.8,'dark')
    return export('BrassIndustrialGatehouseV2')

def refinery():
    # Vertical process landmark: central tower, twin tanks, platform rings and blueglass core.
    box('Base',(0,0,.7),(30,30,1.4),'concrete',.15)
    box('CoreTower',(0,0,12),(12,12,22),'brick',.12)
    box('LowerPlatform',(0,0,11),(25,25,1),'iron_light',.04)
    box('UpperPlatform',(0,0,22),(23,23,1),'iron_light',.04)
    for x in (-9,9):
        for y in (-9,9): box('Leg',(x,y,11),(.65,.65,21),'iron',.02)
    cyl('TankA',(-7,0,17),4.0,15,'iron',14); cyl('TankB',(7,0,19),4.0,19,'iron',14)
    for x,z in [(-7,12),(-7,22),(7,12),(7,26)]: cyl('Band',(x,0,z),4.3,.55,'brass',14)
    pipe('CrossHeader',(-7,0,26),(7,0,28),.7,'copper')
    pipe('DropHeader',(7,0,28),(12,0,14),.7,'copper')
    box('BlueglassCore',(0,-6.1,14),(5,.25,10),'blue',.02)
    pipe('Stack',(0,5,23),(0,5,35),1.0,'dark')
    return export('BrassRefineryTowerV2')

builders=[foundry_admin,machinist,smelter,boiler,barracks,loading,gatehouse,refinery]
manifest={}
for fn in builders:
    clear(); M=materials(); info=fn(); manifest[Path(info['file']).stem]=info
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2))
