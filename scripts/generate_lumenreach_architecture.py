#!/usr/bin/env python3
# Run with: blender --background --python scripts/generate_lumenreach_architecture.py
import bpy, math, json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'original' / 'lumenreach_architecture'
OUT.mkdir(parents=True, exist_ok=True)

PALETTE = {
    'wood': (0.27, 0.17, 0.10, 1),
    'wood_light': (0.46, 0.31, 0.18, 1),
    'plaster': (0.36, 0.45, 0.34, 1),
    'plaster_warm': (0.46, 0.38, 0.26, 1),
    'plaster_violet': (0.34, 0.30, 0.45, 1),
    'roof': (0.08, 0.18, 0.16, 1),
    'roof_alt': (0.12, 0.24, 0.20, 1),
    'stone': (0.26, 0.31, 0.29, 1),
    'metal': (0.34, 0.37, 0.35, 1),
    'lumen': (0.18, 0.95, 0.68, 1),
    'window': (0.14, 0.65, 0.58, 1),
    'cloth': (0.24, 0.52, 0.39, 1),
    'cloth_gold': (0.66, 0.48, 0.18, 1),
}

def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
        pass

def mat(name, rgba, metallic=0.0, rough=0.7, emission=None):
    m=bpy.data.materials.get(name)
    if m: return m
    m=bpy.data.materials.new(name)
    m.diffuse_color=rgba
    m.use_nodes=True
    bsdf=m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=rgba
    bsdf.inputs['Roughness'].default_value=rough
    bsdf.inputs['Metallic'].default_value=metallic
    if emission:
        # Blender 3/4 compatibility
        if 'Emission Color' in bsdf.inputs:
            bsdf.inputs['Emission Color'].default_value=emission
            bsdf.inputs['Emission Strength'].default_value=2.0
        elif 'Emission' in bsdf.inputs:
            bsdf.inputs['Emission'].default_value=emission
    return m

def materials():
    return {k:mat('EL_'+k,v, metallic=(0.45 if k=='metal' else 0), rough=(0.45 if k=='metal' else 0.72), emission=(v if k in ('lumen','window') else None)) for k,v in PALETTE.items()}

M={}

def add_box(name, loc, dims, material, bevel=0.10, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; o.dimensions=dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel>0:
        mod=o.modifiers.new('soft_edges','BEVEL'); mod.width=bevel; mod.segments=1
        bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.materials.append(M[material])
    return o

def add_cylinder(name, loc, radius, depth, material, vertices=8, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rot)
    o=bpy.context.object; o.name=name; o.data.materials.append(M[material]); return o

def add_gable(name, loc, width, depth, wall_top, ridge_height, material, overhang=0.7):
    # solid triangular prism, Z-up
    w=width/2+overhang; d=depth/2+overhang; z0=wall_top; z1=wall_top+ridge_height
    verts=[(-w,-d,z0),(w,-d,z0),(0,-d,z1),(-w,d,z0),(w,d,z0),(0,d,z1)]
    faces=[(0,1,2),(3,5,4),(0,3,4,1),(1,4,5,2),(2,5,3,0)]
    mesh=bpy.data.meshes.new(name+'Mesh'); mesh.from_pydata(verts,[],faces); mesh.update()
    o=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(o); o.location=loc
    o.data.materials.append(M[material])
    bevel=o.modifiers.new('roof_edges','BEVEL'); bevel.width=0.08; bevel.segments=1
    bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=bevel.name)
    return o

def beam_frame(cx, cy, z, width, height, depth=0.22, material='wood'):
    add_box('BeamTop',(cx,cy,z+height/2),(width,depth,0.28),material,0.04)
    add_box('BeamL',(cx-width/2+0.18,cy,z),(0.28,depth,height),material,0.04)
    add_box('BeamR',(cx+width/2-0.18,cy,z),(0.28,depth,height),material,0.04)
    # diagonal braces
    angle=math.atan2(height-0.5,width-0.7)
    length=math.hypot(width-0.7,height-0.5)
    add_box('BraceL',(cx-width*0.23,cy-0.01,z),(0.20,depth*0.8,length*0.52),material,0.03,rot=(0,angle,0))
    add_box('BraceR',(cx+width*0.23,cy-0.01,z),(0.20,depth*0.8,length*0.52),material,0.03,rot=(0,-angle,0))

def window(x,y,z,w=2.0,h=2.8, facing='front'):
    if facing=='front':
        add_box('Window',(x,y,z),(w,0.16,h),'window',0.03)
        add_box('WinTop',(x,y-0.02,z+h/2+0.16),(w+0.35,0.22,0.22),'wood',0.03)
        add_box('WinBottom',(x,y-0.02,z-h/2-0.16),(w+0.35,0.22,0.22),'wood',0.03)
        add_box('WinL',(x-w/2-0.16,y-0.02,z),(0.22,0.22,h+0.65),'wood',0.03)
        add_box('WinR',(x+w/2+0.16,y-0.02,z),(0.22,0.22,h+0.65),'wood',0.03)
    else:
        add_box('Window',(x,y,z),(0.16,w,h),'window',0.03)

def door(x,y,z,w=2.6,h=4.4):
    add_box('Door',(x,y,z),(w,0.24,h),'wood_light',0.05)
    add_box('DoorTop',(x,y-0.03,z+h/2+0.18),(w+0.55,0.32,0.28),'wood',0.04)
    add_box('DoorL',(x-w/2-0.23,y-0.03,z),(0.30,0.32,h+0.6),'wood',0.04)
    add_box('DoorR',(x+w/2+0.23,y-0.03,z),(0.30,0.32,h+0.6),'wood',0.04)

def foundation(width, depth):
    add_box('Foundation',(0,0,0.6),(width+1.2,depth+1.2,1.2),'stone',0.18)

def wall_shell(width, depth, height, wallmat='plaster', door_center=0, front_windows=True):
    t=0.45; z=1.2+height/2
    add_box('BackWall',(0,depth/2,z),(width,t,height),wallmat,0.10)
    add_box('LeftWall',(-width/2,0,z),(t,depth,height),wallmat,0.10)
    add_box('RightWall', (width/2,0,z),(t,depth,height),wallmat,0.10)
    # front segmented around centered door
    dw=3.5; leftw=(width-dw)/2
    add_box('FrontL',(-(dw/2+leftw/2),-depth/2,z),(leftw,t,height),wallmat,0.10)
    add_box('FrontR',((dw/2+leftw/2),-depth/2,z),(leftw,t,height),wallmat,0.10)
    # facade post rhythm
    for x in (-width/2, -width/4, width/4, width/2):
        add_box('FacadePost',(x,-depth/2-0.28,z),(0.32,0.32,height+0.7),'wood',0.04)
    door(door_center,-depth/2-0.28,1.2+2.2)
    if front_windows and width>=16:
        window(-width*0.30,-depth/2-0.29,1.2+height*0.58,2.1,2.6)
        window(width*0.30,-depth/2-0.29,1.2+height*0.58,2.1,2.6)

def porch(width, depth, y, roof_z=None, posts=3, cloth=False):
    add_box('PorchFloor',(0,y,1.15),(width,depth,0.48),'wood_light',0.08)
    x0=-width/2+0.6; x1=width/2-0.6
    for i in range(posts):
        x=x0+(x1-x0)*(i/(posts-1) if posts>1 else 0.5)
        add_box('PorchPost',(x,y-depth/2+0.4,4.1),(0.35,0.35,6.0),'wood',0.04)
    if roof_z:
        matname='cloth' if cloth else 'roof_alt'
        add_box('PorchRoof',(0,y,roof_z),(width+0.7,depth+0.8,0.32),matname,0.06,rot=(math.radians(4),0,0))

def chimney(x,y,height=6):
    add_box('Chimney',(x,y,1.2+height/2),(1.7,1.7,height),'stone',0.12)
    add_box('ChimneyCap',(x,y,1.2+height+0.25),(2.1,2.1,0.5),'stone',0.10)

def join_and_export(name):
    bpy.ops.object.select_all(action='DESELECT')
    mesh_objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in mesh_objs: o.select_set(True)
    bpy.context.view_layer.objects.active=mesh_objs[0]
    bpy.ops.object.join()
    obj=bpy.context.object; obj.name=name
    # origin at world ground center, apply no location shift
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # weighted normals where available
    try:
        mod=obj.modifiers.new('weighted_normals','WEIGHTED_NORMAL'); mod.keep_sharp=True
        bpy.context.view_layer.objects.active=obj; bpy.ops.object.modifier_apply(modifier=mod.name)
    except Exception:
        pass
    path=OUT/(name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=False, export_apply=True, export_materials='EXPORT')
    tris=sum(len(p.vertices)-2 for p in obj.data.polygons)
    return {'file':str(path.relative_to(ROOT)), 'triangles':tris, 'vertices':len(obj.data.vertices), 'materials':len(obj.data.materials)}

def civic_hall():
    foundation(34,23); wall_shell(34,23,9,'plaster')
    add_gable('MainRoof',(0,0,0),34,23,10.2,7.5,'roof',1.0)
    # tall asymmetric entry tower
    add_box('TowerBody',(0,-14.2,7.0),(8.5,7.0,11.6),'plaster_violet',0.13)
    beam_frame(0,-17.75,7.2,7.8,9.8)
    add_gable('TowerRoof',(0,-14.2,0),9.5,8.0,13.0,5.8,'roof_alt',0.6)
    porch(20,5.5,-14.2,7.8,3)
    chimney(11,4,8)
    # side council bay
    add_box('CouncilBay',(19,3,4.5),(8,12,6.5),'plaster_warm',0.12)
    add_gable('BayRoof',(19,3,0),9,13,7.7,4.0,'roof_alt',0.5)
    return join_and_export('LumenCivicHall')

def quartermaster():
    foundation(27,20); wall_shell(27,20,8,'plaster_warm')
    add_gable('DepotRoof',(0,0,0),27,20,9.2,5.6,'roof',0.9)
    porch(19,6,-12.7,6.8,3)
    # side loading shed and hoist frame
    add_box('LoadingDeck',(17,1,1.25),(8,15,0.6),'wood_light',0.07)
    for y in (-5,5): add_box('LoadPost',(20,y,4.0),(0.4,0.4,6.0),'wood',0.04)
    add_box('LoadBeam',(20,0,7.0),(0.45,12,0.45),'wood',0.04)
    add_box('HoistArm',(20,-6.0,8.2),(0.45,4.0,0.45),'wood',0.04,rot=(math.radians(-15),0,0))
    add_cylinder('HoistWheel',(20,-7.5,7.4),0.8,0.35,'metal',10,rot=(math.radians(90),0,0))
    chimney(-9,4,7)
    return join_and_export('LumenQuartermasterDepot')

def archive():
    foundation(25,19); wall_shell(25,19,8,'plaster_violet')
    add_gable('ArchiveRoof',(0,0,0),25,19,9.2,7.0,'roof',0.8)
    # octagonal-ish observatory turret
    add_cylinder('Turret',(15,3,5.5),5.2,8.5,'stone',8)
    add_cylinder('TurretBand',(15,3,9.6),5.6,0.7,'metal',8)
    add_cylinder('Beacon',(15,3,13.2),1.2,6.0,'lumen',8)
    add_gable('ReadingRoof',(-7,-12,0),12,7,6.8,3.5,'roof_alt',0.5)
    porch(14,5,-12,6.6,2)
    chimney(-8,3,7)
    return join_and_export('LumenArchiveLodge')

def inn():
    foundation(31,20); wall_shell(31,20,8,'plaster')
    add_gable('InnRoof',(0,0,0),31,20,9.2,6.2,'roof',1.0)
    # perpendicular social wing
    add_box('WingBody',(18,5,5.1),(11,16,7.8),'plaster_warm',0.12)
    add_gable('WingRoof',(18,5,0),12,17,9.0,4.5,'roof_alt',0.6)
    porch(23,6,-13.0,7.0,4)
    chimney(-10,4,8)
    chimney(20,6,6)
    # hanging sign
    add_box('SignPost',(-13,-14.5,5),(0.35,0.35,7),'wood',0.04)
    add_box('SignArm',(-11.2,-14.5,8.0),(3.6,0.32,0.32),'wood',0.04)
    add_box('Sign',(-10,-14.5,6.9),(2.6,0.25,1.7),'cloth_gold',0.08)
    return join_and_export('LumenWayfarerInn')

def healer():
    foundation(22,16); wall_shell(22,16,7,'plaster')
    add_gable('HealerRoof',(0,0,0),22,16,8.2,5.4,'roof_alt',0.9)
    porch(18,6,-10.8,6.8,3,cloth=True)
    # herb rack silhouettes
    for x in (-7,-2,3,8):
        add_box('HerbRackPost',(x,-14,3.5),(0.25,0.25,5.0),'wood',0.03)
        add_box('HerbBundle',(x,-14,5.4),(0.8,0.5,1.8),'cloth',0.08)
    chimney(7,3,6)
    # garden-side glasshouse lean-to
    add_box('GlassLean',(-14,2,4.2),(7,12,0.25),'window',0.03,rot=(0,math.radians(-10),0))
    return join_and_export('LumenHealerLodge')

def workshop():
    foundation(30,21)
    # rear block only, open front
    add_box('RearWall',(0,10.5,5.7),(30,0.55,9),'plaster_warm',0.1)
    add_box('LeftWall',(-15,3,5.7),(0.55,15,9),'plaster_warm',0.1)
    add_gable('WorkshopRoof',(0,0,0),30,21,10.0,5.0,'roof',0.9)
    for x in (-13,-5,5,13): add_box('FrontPost',(x,-9.5,5.0),(0.45,0.45,8.0),'wood',0.05)
    add_box('CrossBeam',(0,-9.5,8.7),(28,0.45,0.45),'wood',0.05)
    # workbench, racks, vent hood
    add_box('Workbench',(5,3,2.3),(11,4,2.0),'wood_light',0.08)
    for x in (-8,-4,0): add_box('ToolRack',(x,9.8,5.2),(2.2,0.4,5.2),'wood',0.05)
    add_gable('ForgeHood',(-9,2,0),7,6,6.7,3.0,'metal',0.4)
    chimney(-9,4,9)
    return join_and_export('LumenCraftWorkshop')

def stable():
    foundation(31,21)
    add_box('StableBack',(0,10.5,5.2),(31,0.55,8),'plaster_warm',0.1)
    add_gable('StableRoof',(0,0,0),31,21,9.0,5.7,'roof',1.0)
    for x in (-14,-5,5,14): add_box('StablePost',(x,-9.2,4.8),(0.45,0.45,7.5),'wood',0.05)
    for x in (-10,0,10): add_box('StallDivider',(x,3,3.3),(0.45,13,5.0),'wood',0.05)
    add_box('TackShed',(18,3,4.2),(8,10,6.2),'plaster',0.1)
    add_gable('TackRoof',(18,3,0),9,11,7.3,3.6,'roof_alt',0.5)
    # loft face
    add_box('LoftFace',(0,10.15,9.2),(14,0.35,3.8),'wood_light',0.05)
    return join_and_export('LumenOpenStable')

def proving():
    foundation(28,17); wall_shell(28,17,7.5,'plaster')
    add_gable('ProvingRoof',(0,0,0),28,17,8.8,6.7,'roof',0.8)
    # training pavilion front with tall open frame and emblem beam
    porch(20,6,-11.2,7.2,3)
    add_box('EmblemBeam',(0,-14,9.1),(18,0.4,0.55),'wood',0.05)
    add_cylinder('Emblem',(0,-14.25,7.7),1.3,0.25,'lumen',10,rot=(math.radians(90),0,0))
    # side weapon racks
    for y in (-3,2,7):
        add_box('Rack',(16,y,3.8),(0.5,4.5,5.2),'wood_light',0.05)
    return join_and_export('LumenProvingLodge')



def road_wayhouse():
    foundation(25,16)
    add_box('ServiceRoom',(-5,1,5.2),(14,14,8.0),'plaster',0.12)
    add_gable('ServiceRoof',(-5,1,0),15,15,9.0,4.8,'roof_alt',0.7)
    add_box('OpenDeck',(9,-1,1.25),(13,14,0.6),'wood_light',0.08)
    for x in (4,14):
        add_box('WayhousePost',(x,-6.5,4.8),(0.42,0.42,7.2),'wood',0.05)
        add_box('WayhouseRearPost',(x,5.0,4.8),(0.42,0.42,7.2),'wood',0.05)
    add_box('Canopy',(9,-0.5,8.4),(14.5,15.5,0.42),'roof',0.06,rot=(0,math.radians(-7),0))
    door(-5,-6.25,3.5,2.8,4.3)
    window(-8.5,-6.26,5.0,1.8,2.4)
    add_box('NoticeBoard',(9,-7.2,4.2),(5.2,0.28,3.2),'wood_light',0.06)
    add_box('SupplyBench',(9,4.0,2.1),(7.5,2.3,1.6),'wood_light',0.08)
    return join_and_export('LumenRoadWayhouse')

def farm_barn():
    foundation(28,20)
    wall_shell(28,20,9,'plaster_warm',front_windows=False)
    add_gable('BarnRoof',(0,0,0),28,20,10.2,8.4,'roof',1.0)
    add_box('LoftDoor',(0,-10.3,9.2),(6.5,0.25,5.3),'wood_light',0.05)
    add_box('LeanDeck',(18,2,1.25),(8,14,0.6),'wood_light',0.08)
    for y in (-4,6): add_box('LeanPost',(21,y,4.1),(0.42,0.42,6.2),'wood',0.05)
    add_box('LeanRoof',(18,2,7.2),(10,16,0.38),'roof_alt',0.06,rot=(0,math.radians(9),0))
    add_box('HayLoftVent',(0,-10.45,13.2),(4.0,0.22,2.3),'window',0.04)
    return join_and_export('LumenFarmBarn')

def croft_cottage_a():
    foundation(22,17); wall_shell(22,17,8,'plaster')
    add_gable('CottageRoof',(0,0,0),22,17,9.2,5.3,'roof_alt',0.8)
    add_box('LeanBody',(14,2,4.1),(8,11,6.0),'plaster_warm',0.10)
    add_box('LeanRoof',(14,2,7.4),(10,13,0.35),'roof',0.05,rot=(0,math.radians(9),0))
    porch(10,4.5,-10.2,6.6,2)
    chimney(7,4,6.5)
    return join_and_export('LumenCroftCottageA')

def croft_cottage_b():
    foundation(20,18); wall_shell(20,18,7.5,'plaster_warm')
    add_gable('CottageRoof',(0,0,0),20,18,8.7,6.6,'roof',0.9)
    add_box('SideBay',(-13,-1,4.2),(7,10,6.2),'plaster',0.10)
    add_gable('BayRoof',(-13,-1,0),8,11,7.4,3.3,'roof_alt',0.5)
    porch(12,5,-11.1,6.3,2)
    chimney(6,4,6.0)
    add_box('WoodRack',(12,6,2.4),(5.5,2.0,3.0),'wood_light',0.06)
    return join_and_export('LumenCroftCottageB')

def glowmere_stilt_house():
    # Entire occupied volume is raised above wet ground/water.
    for x in (-7,7):
        for y in (-5,5): add_box('Stilt',(x,y,4.0),(0.6,0.6,8.0),'wood',0.05)
    add_box('RaisedFloor',(0,0,5.8),(16,13,0.7),'wood_light',0.08)
    add_box('BackWall',(0,5.8,9.4),(16,0.5,6.8),'plaster',0.09)
    add_box('LeftWall',(-7.8,0,9.4),(0.5,12,6.8),'plaster',0.09)
    add_box('RightWall',(7.8,0,9.4),(0.5,12,6.8),'plaster',0.09)
    add_box('FrontL',(-5.2,-5.8,9.4),(5.5,0.5,6.8),'plaster',0.09)
    add_box('FrontR',(5.2,-5.8,9.4),(5.5,0.5,6.8),'plaster',0.09)
    add_gable('StiltRoof',(0,0,0),16,13,12.8,4.7,'roof_alt',1.0)
    add_box('FrontDeck',(0,-9.0,5.8),(12,6,0.65),'wood_light',0.07)
    add_box('DockRamp',(0,-14.0,5.0),(5.5,8.5,0.5),'wood_light',0.06,rot=(math.radians(-8),0,0))
    add_box('ReedAwning',(8,-8,9.0),(8,7,0.35),'cloth',0.05,rot=(math.radians(5),0,0))
    door(0,-6.1,8.0,2.6,4.0)
    window(-4.5,-6.1,9.5,1.8,2.2)
    window(4.5,-6.1,9.5,1.8,2.2)
    return join_and_export('LumenGlowmereStiltHouse')

def mossglen_ranger_hall():
    foundation(34,23); wall_shell(34,23,8.5,'plaster')
    add_gable('RangerRoof',(0,0,0),34,23,9.7,7.3,'roof',1.0)
    porch(25,6,-14.3,7.2,4)
    # raised lookout wing
    for y in (-2,6): add_box('LookoutPost',(21,y,4.0),(0.55,0.55,8.0),'wood',0.05)
    add_box('LookoutDeck',(21,2,8.0),(10,10,0.7),'wood_light',0.08)
    add_box('LookoutRoof',(21,2,13.2),(11,11,0.45),'roof_alt',0.06,rot=(0,math.radians(-5),0))
    add_box('DryingRack',(-14,-15.5,4.0),(8,0.35,5.5),'wood',0.04)
    for x in (-16,-12): add_box('RackPost',(x,-15.5,3.5),(0.3,0.3,6.0),'wood',0.03)
    chimney(10,5,7.0)
    return join_and_export('LumenMossglenRangerHall')

def frontier_gatehouse():
    add_box('LeftTower',(-15,0,8.5),(9,12,17),'stone',0.18)
    add_box('RightTower',(15,0,8.5),(9,12,17),'stone',0.18)
    add_box('GateLintel',(0,0,15.0),(21,8,4.0),'stone',0.15)
    add_box('LeftPlatform',(-15,0,17.8),(11,14,1.0),'wood_light',0.08)
    add_box('RightPlatform',(15,0,17.8),(11,14,1.0),'wood_light',0.08)
    for x in (-19,-11,11,19): add_box('Parapet',(x,-6.0,20.0),(2.5,2.0,4.0),'stone',0.08)
    add_box('ControlHut',(20,4,6.0),(7,8,10),'plaster_warm',0.12)
    add_gable('ControlRoof',(20,4,0),8,9,11.0,3.3,'roof_alt',0.5)
    add_box('BannerL',(-15,-6.2,11.0),(3.0,0.25,6.0),'cloth',0.04)
    add_box('BannerR',(15,-6.2,11.0),(3.0,0.25,6.0),'cloth_gold',0.04)
    return join_and_export('LumenFrontierGatehouse')

def ruined_hall():
    add_box('RuinFloor',(0,0,0.6),(30,22,1.2),'stone',0.12)
    add_box('BackWall',(-3,10.5,5.0),(23,1.0,10.0),'stone',0.14)
    add_box('LeftWall',(-14.5,2.0,4.0),(1.0,15.0,8.0),'stone',0.14)
    add_box('RightStub',(14.5,6.0,2.8),(1.0,8.0,5.5),'stone',0.14)
    add_box('BrokenFrontL',(-10,-10.5,3.2),(9,1.0,6.2),'stone',0.14)
    add_box('BrokenFrontR',(11,-10.5,2.3),(7,1.0,4.5),'stone',0.14)
    # collapsed roof fragments and broken rafters
    add_box('RoofFragment',(-5,4,10.5),(13,8,0.6),'roof',0.06,rot=(0,math.radians(16),0))
    add_box('FallenBeam',(5,-1,1.5),(0.55,14,0.55),'wood',0.04,rot=(math.radians(82),0,math.radians(12)))
    add_box('BrokenPillar',(-7,-3,4.0),(2.2,2.2,8.0),'stone',0.12)
    add_box('BrokenPillar',(8,4,3.0),(2.2,2.2,6.0),'stone',0.12)
    return join_and_export('LumenRuinedHall')


builders=[civic_hall,quartermaster,archive,inn,healer,workshop,stable,proving,road_wayhouse,farm_barn,croft_cottage_a,croft_cottage_b,glowmere_stilt_house,mossglen_ranger_hall,frontier_gatehouse,ruined_hall]
manifest={}
for fn in builders:
    clear(); M=materials(); globals()['M']=M
    info=fn(); manifest[Path(info['file']).stem]=info
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2))
