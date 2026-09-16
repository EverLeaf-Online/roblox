#!/usr/bin/env python3
# Run with: blender --background --python scripts/generate_brasshaven_architecture.py
import bpy, math, json, struct, zlib, binascii
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'original' / 'brasshaven_architecture'
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
KEYS=list(PALETTE.keys()); GRID=4; CELL=16; ATLAS=OUT/'brass_palette.png'

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
    m=bpy.data.materials.get('EL_BrasshavenPalette') or bpy.data.materials.new('EL_BrasshavenPalette'); m.use_nodes=True
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
    box('Foundation',(0,0,.6),(34,24,1.2),'concrete',.15)
    box('MainHall',(0,0,6.1),(28,20,10),'brick_light',.12)
    box('EntryTower',(0,-12.5,10),(10,7,18),'brick',.12)
    box('TowerCap',(0,-12.5,19.5),(12,9,1.2),'brass',.08)
    box('Roof',(0,0,11.6),(30,22,1.2),'iron',.08)
    box('Canopy',(0,-13.5,6.2),(16,5,.7),'brass',.06)
    for x in (-6,6): box('CanopyPost',(x,-15,3.4),(.5,.5,6.2),'iron',.03)
    windows_front(28,-10.15,6.2,4)
    box('Door',(0,-15.9,4.2),(3.8,.28,6.2),'dark',.04)
    return export('BrassFoundryAdminHall')

def machinist():
    box('Foundation',(0,0,.55),(38,24,1.1),'concrete',.12)
    box('ShopBody',(-5,0,5.8),(27,20,9.5),'brick',.1)
    box('MachineBay',(14,2,5.0),(12,16,8),'iron_light',.08)
    box('SawRoofA',(-10,0,11),(12,22,1),'iron',.04,rot=(0,math.radians(12),0))
    box('SawRoofB',(2,0,11),(12,22,1),'iron',.04,rot=(0,math.radians(-12),0))
    box('LoadingCanopy',(17,-9,7.0),(11,7,.6),'brass',.05)
    for x in (12,20): box('Post',(x,-11.5,3.6),(.45,.45,6.5),'iron',.03)
    windows_front(27,-10.15,5.6,3)
    pipe('Pipe',(-12,9,9),(-12,9,17),.9,'copper')
    cyl('Vent',(-12,9,18),1.5,2.5,'iron',10)
    return export('BrassMachinistWorkshop')

def smelter():
    box('Foundation',(0,0,.6),(32,28,1.2),'concrete',.14)
    box('FurnaceHall',(-3,0,7.2),(24,22,12),'brick',.12)
    box('Roof',(-3,0,13.5),(26,24,1.2),'iron',.06)
    box('FurnaceAnnex',(15,1,5.2),(10,16,8),'iron_light',.08)
    for x in (-8,1):
        pipe('Stack',(x,6,11),(x,6,25),1.35,'dark'); cyl('StackCap',(x,6,25.5),1.8,1.2,'iron',12)
    box('FurnaceMouth',(7,-11.2,4.5),(6,.3,4.2),'hot',.02)
    pipe('FeedPipe',(12,6,8),(19,6,8),.8,'copper')
    windows_front(24,-11.15,7,2)
    return export('BrassSmelterHouse')

def boiler():
    box('Foundation',(0,0,.55),(30,24,1.1),'concrete',.12)
    box('ServiceHouse',(-8,0,5.4),(14,20,8.5),'brick_light',.1)
    box('ServiceRoof',(-8,0,10),(16,22,1),'iron',.05)
    for x in (4,12):
        cyl('Boiler',(x,1,6.8),4.0,12,'iron',14)
        cyl('BoilerBand',(x,1,4.2),4.3,.55,'brass',14); cyl('BoilerBand',(x,1,9.0),4.3,.55,'brass',14)
        pipe('Stack',(x,1,12.8),(x,1,20),1.0,'dark')
    pipe('Header',(4,1,12),(12,1,12),.7,'copper')
    box('Door',(-8,-10.2,4),(3.5,.25,5.5),'dark',.03)
    return export('BrassBoilerStation')

def barracks():
    box('Foundation',(0,0,.55),(38,24,1.1),'concrete',.12)
    box('WingA',(-8,0,5.8),(20,20,9.5),'brick_light',.1)
    box('WingB',(12,4,5.0),(14,13,8),'brick',.1)
    box('RoofA',(-8,0,11),(22,22,1),'iron',.05)
    box('RoofB',(12,4,9.6),(16,15,1),'iron',.05)
    windows_front(20,-10.15,5.8,3)
    box('EntryCanopy',(2,-11.8,6.5),(9,4,.55),'brass',.05)
    box('Door',(2,-10.25,4.2),(3.4,.24,5.8),'dark',.03)
    return export('BrassWorkerBarracks')

def loading():
    box('Foundation',(0,0,.55),(40,26,1.1),'concrete',.12)
    box('DepotBody',(-9,2,5.8),(21,20,9.5),'brick',.1)
    box('DepotRoof',(-9,2,11),(23,22,1),'iron',.05)
    box('LoadingDeck',(12,-2,1.2),(19,22,.7),'iron_light',.05)
    box('Canopy',(12,-2,9.0),(20,23,.7),'brass',.05)
    for x in (4,12,20): box('CanopyPost',(x,-10,4.8),(.5,.5,8),'iron',.03)
    box('HoistBeam',(21,0,13),(1,22,1),'iron',.03)
    pipe('HoistArm',(21,-9,13),(24,-13,13),.45,'brass')
    windows_front(21,-8.15,5.8,2)
    return export('BrassLoadingDepot')

def gatehouse():
    box('LeftTower',(-14,0,10),(9,12,20),'brick',.12); box('RightTower',(14,0,10),(9,12,20),'brick',.12)
    box('Lintel',(0,0,18),(20,10,6),'iron',.08); box('TopBand',(0,0,22),(32,13,1.2),'brass',.06)
    box('ControlRoom',(21,4,6.5),(8,10,11),'brick_light',.1); box('ControlRoof',(21,4,12.5),(10,12,1),'iron',.05)
    for x in (-14,14): box('Banner',(x,-6.2,11),(3,.2,7),'cloth',.02)
    box('Warning',(0,-5.2,17),(8,.18,1.2),'hot',.02)
    return export('BrassIndustrialGatehouse')

def refinery():
    box('Foundation',(0,0,.7),(24,24,1.4),'concrete',.14)
    box('Core',(0,0,11),(12,12,20),'brick',.12)
    box('Platform',(0,0,18),(21,21,1),'iron_light',.05)
    for x in (-8,8):
        for y in (-8,8): box('Leg',(x,y,9),(.7,.7,17),'iron',.03)
    cyl('UpperTank',(0,0,24),5.0,10,'iron',14)
    cyl('UpperBand',(0,0,21),5.4,.6,'brass',14); cyl('UpperBand',(0,0,27),5.4,.6,'brass',14)
    pipe('SidePipe',(5,0,22),(10,0,22),.7,'copper'); pipe('DropPipe',(10,0,22),(10,0,5),.7,'copper')
    box('Blueglass',(0,-6.2,11),(5,.2,7),'blue',.02)
    return export('BrassRefineryTower')

builders=[foundry_admin,machinist,smelter,boiler,barracks,loading,gatehouse,refinery]
manifest={}
for fn in builders:
    clear(); M=materials(); info=fn(); manifest[Path(info['file']).stem]=info
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2))
