#!/usr/bin/env python3
# Original EverLeaf Brasshaven monster roster. Each builder has a distinct industrial
# silhouette; shared helpers only handle mesh primitives and standard animation anchors.
import bpy, math, json, struct, zlib, binascii
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'original'/'brasshaven_monsters'; OUT.mkdir(parents=True,exist_ok=True)
PAL={
 'iron':(.20,.22,.22,1),'iron2':(.34,.36,.34,1),'dark':(.09,.10,.10,1),'brass':(.58,.36,.13,1),
 'copper':(.48,.23,.11,1),'brick':(.34,.22,.16,1),'slag':(.23,.20,.17,1),'ember':(.98,.25,.04,1),
 'blue':(.14,.60,.91,1),'blue2':(.42,.88,1.0,1),'ash':(.42,.39,.35,1),'cloth':(.30,.19,.16,1),
 'glass':(.20,.54,.61,1),'oil':(.12,.13,.12,1),'bone':(.58,.54,.47,1),'white':(.82,.79,.66,1)
}
KEYS=list(PAL); GRID=4; CELL=16; ATLAS=OUT/'brass_monster_palette.png'; MAT=None

def png():
 w=h=GRID*CELL; rows=[]
 for y in range(h):
  row=bytearray([0]); cy=y//CELL
  for x in range(w):
   i=cy*GRID+x//CELL; c=PAL[KEYS[i]][:3] if i<len(KEYS) else (1,0,1); row.extend(round(v*255) for v in c)
  rows.append(bytes(row))
 def ch(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',binascii.crc32(t+d)&0xffffffff)
 ATLAS.write_bytes(b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+ch(b'IDAT',zlib.compress(b''.join(rows),9))+ch(b'IEND',b''))

def material():
 png(); img=bpy.data.images.load(str(ATLAS),check_existing=True); m=bpy.data.materials.new('EL_BrassMonsterPalette'); m.use_nodes=True
 b=m.node_tree.nodes.get('Principled BSDF'); t=m.node_tree.nodes.new('ShaderNodeTexImage'); t.image=img; t.interpolation='Closest'; m.node_tree.links.new(t.outputs['Color'],b.inputs['Base Color']); b.inputs['Roughness'].default_value=.58; return m

def clear(): bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def uv(o,key):
 i=KEYS.index(key); u=(i%GRID+.5)/GRID; v=1-(i//GRID+.5)/GRID; layer=o.data.uv_layers.get('UVMap') or o.data.uv_layers.new(name='UVMap')
 for poly in o.data.polygons:
  for li in poly.loop_indices: layer.data[li].uv=(u,v)
 o.data.materials.clear(); o.data.materials.append(MAT)
def box(n,loc,d,key,rot=(0,0,0),bev=.08):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot); o=bpy.context.object; o.name=n; o.dimensions=d; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bev:
  md=o.modifiers.new('edge','BEVEL'); md.width=bev; md.segments=1; bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=md.name)
 uv(o,key); return o
def sph(n,loc,d,key,seg=12,rings=8):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=loc); o=bpy.context.object; o.name=n; o.scale=(d[0]/2,d[1]/2,d[2]/2); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); uv(o,key); return o
def cyl(n,loc,r,depth,key,rot=(0,0,0),verts=10):
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=loc,rotation=rot); o=bpy.context.object; o.name=n; uv(o,key); return o
def cone(n,loc,r1,r2,depth,key,rot=(0,0,0),verts=8):
 bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=depth,location=loc,rotation=rot); o=bpy.context.object; o.name=n; uv(o,key); return o
def torus(n,loc,major,minor,key,rot=(0,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=12,minor_segments=6,location=loc,rotation=rot); o=bpy.context.object; o.name=n; uv(o,key); return o
def export(name):
 path=OUT/(name+'.glb'); bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_materials='EXPORT'); objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
 return {'file':str(path.relative_to(ROOT)),'parts':[o.name for o in objs],'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objs)}
def qleg(name,x,z,h=2.2,key='iron'):
 box(name,(x,h/2,z),(.72,h,.75),key,rot=(0,0,math.radians(-7 if x<0 else 7)),bev=.12)
def human_base(bodyz=4.2,scale=1.0,bodykey='iron',limbkey='iron2'):
 box('Body',(0,bodyz,0),(2.5*scale,3.0*scale,1.5*scale),bodykey,bev=.18); box('Head',(0,bodyz+2.2,-.08),(1.75*scale,1.55*scale,1.45*scale),bodykey,bev=.18)
 box('LeftArm',(-1.75*scale,bodyz-.1,0),(.75*scale,3.1*scale,.8*scale),limbkey,rot=(0,0,math.radians(-3)),bev=.12); box('RightArm',(1.75*scale,bodyz-.1,0),(.75*scale,3.1*scale,.8*scale),limbkey,rot=(0,0,math.radians(3)),bev=.12)
 box('LeftLeg',(-.65*scale,bodyz-2.7,.1),(.85*scale,2.6*scale,.9*scale),limbkey,bev=.12); box('RightLeg',(.65*scale,bodyz-2.7,.1),(.85*scale,2.6*scale,.9*scale),limbkey,bev=.12)

def rivet_scuttler():
 sph('Body',(0,2.0,.1),(3.4,1.7,3.8),'iron',12,7); box('Head',(0,1.95,-2.05),(2.1,1.25,1.2),'brass',bev=.18)
 for name,x,z in [('FrontLeftLeg',-1.55,-1.15),('FrontRightLeg',1.55,-1.15),('BackLeftLeg',-1.55,1.2),('BackRightLeg',1.55,1.2)]: qleg(name,x,z,2.0,'iron2')
 for x in (-.5,.5): sph('EyeL' if x<0 else 'EyeR',(x,2.15,-2.72),(.3,.3,.18),'blue2',8,5)
 for i,x in enumerate((-1.0,0,1.0)): cone('RivetSpike'+str(i+1),(x,3.0,.35),.25,.03,1.15,'brass',verts=6)
 return export('RivetScuttler')
def slagmite():
 sph('Body',(0,1.7,0),(4.4,3.1,4.2),'slag',12,8); sph('Head',(0,2.1,-1.45),(2.2,1.25,1.0),'slag',10,6)
 for x in (-.55,.55): sph('EyeL' if x<0 else 'EyeR',(x,2.28,-1.95),(.26,.25,.16),'ember',8,5)
 for i,(x,z,h) in enumerate([(-1.25,.4,1.8),(1.2,.2,1.4),(0,1.2,2.1)]): cone('SlagSpire'+str(i+1),(x,3.05,z),.52,.08,h,'iron',verts=7)
 torus('FurnaceRing',(0,2.4,0),1.45,.18,'brass',rot=(math.radians(90),0,0)); sph('HeatCore',(0,2.45,-.4),(1.2,.75,.45),'ember',10,6)
 return export('Slagmite')
def gearjaw_hound():
 box('Body',(0,2.4,.25),(4.2,2.0,3.0),'iron',bev=.25); box('Head',(0,2.5,-2.0),(2.6,1.8,1.8),'iron2',bev=.22)
 for name,x,z in [('FrontLeftLeg',-1.45,-1.15),('FrontRightLeg',1.45,-1.15),('BackLeftLeg',-1.45,1.25),('BackRightLeg',1.45,1.25)]: qleg(name,x,z,2.3,'iron')
 box('Jaw',(0,1.95,-3.0),(2.35,.65,1.0),'dark',bev=.1)
 for i,x in enumerate((- .8,-.3,.3,.8)): cone('Tooth'+str(i+1),(x,1.8,-3.45),.18,.03,.75,'white',rot=(math.radians(90),0,0),verts=5)
 torus('GearCollar',(0,2.45,-.75),1.25,.22,'brass',rot=(math.radians(90),0,0)); box('Tail',(0,2.55,2.25),(.5,.6,2.3),'iron2',rot=(math.radians(-22),0,0),bev=.1)
 return export('GearjawHound')
def cindercoil():
 torus('Body',(0,3.7,0),1.55,.42,'copper',rot=(math.radians(90),0,0)); sph('Core',(0,3.7,0),(2.0,2.0,1.2),'ember',12,7)
 for i,a in enumerate((0,120,240)): box('ArcFin'+str(i+1),(math.cos(math.radians(a))*2.1,3.7,math.sin(math.radians(a))*2.1),(.45,1.4,1.5),'iron',rot=(0,math.radians(-a),math.radians(18)),bev=.08)
 cone('Tail',(0,3.1,2.4),.65,.08,3.2,'ember',rot=(math.radians(65),0,0),verts=8); sph('Sensor',(0,3.75,-1.35),(.65,.65,.45),'blue2',8,5)
 return export('Cindercoil')
def pressure_bastion():
 box('Body',(0,3.0,.2),(6.3,3.3,5.0),'iron',bev=.35); box('Head',(0,3.2,-3.0),(3.6,2.5,1.5),'brass',bev=.25)
 for name,x,z in [('FrontLeftLeg',-2.35,-1.7),('FrontRightLeg',2.35,-1.7),('BackLeftLeg',-2.35,1.8),('BackRightLeg',2.35,1.8)]: qleg(name,x,z,3.0,'iron2')
 cyl('PressureTankL',(-2.2,5.1,.7),.75,3.7,'copper',verts=12); cyl('PressureTankR',(2.2,5.1,.7),.75,3.7,'copper',verts=12)
 box('Ram',(0,2.3,-4.15),(1.3,1.4,2.2),'iron2',bev=.14); sph('Gauge',(0,4.4,-2.65),(1.0,1.0,.25),'white',10,6)
 return export('PressureBastion')
def furnace_husk():
 human_base(4.0,1.0,'brick','iron'); box('FacePlate',(0,5.95,-.75),(1.5,1.15,.22),'dark',bev=.08); sph('EyeL',(-.45,6.05,-.9),(.22,.22,.12),'ember',8,5); sph('EyeR',(.45,6.05,-.9),(.22,.22,.12),'ember',8,5)
 box('ChestDoor',(0,4.1,-.85),(1.65,1.85,.2),'iron2',bev=.08); sph('FurnaceCore',(0,4.1,-1.0),(1.0,1.2,.35),'ember',10,6); cyl('BackStack',(0,.65,5.1),.42,4.0,'dark',verts=9)
 box('RightHand_Clinker', (1.9,2.55,-.2),(1.2,1.0,1.0),'slag',bev=.12)
 return export('FurnaceHusk')
def arc_siphon():
 sph('Body',(0,4.0,0),(2.3,2.3,2.3),'iron',12,7); torus('Coil',(0,4.0,0),1.85,.20,'copper',rot=(math.radians(90),0,0)); torus('Coil2',(0,4.0,0),1.4,.14,'blue',rot=(0,math.radians(90),0))
 sph('Core',(0,4.0,0),(1.2,1.2,1.2),'blue2',10,6); for_positions=[(-2.0,4.0,0),(2.0,4.0,0),(0,4.0,2.0)]
 for i,pos in enumerate(for_positions): cone('SiphonNeedle'+str(i+1),pos,.28,.03,1.8,'brass',rot=(0,math.radians(i*120),math.radians(90)),verts=6)
 cone('Tail',(0,2.2,.5),.45,.03,3.0,'blue',verts=7)
 return export('ArcSiphon')
def railbreaker():
 box('Body',(0,3.1,.2),(7.2,3.4,5.4),'iron',bev=.35); box('Head',(0,3.35,-3.15),(4.2,2.4,1.6),'iron2',bev=.22)
 for name,x,z in [('FrontLeftLeg',-2.7,-1.8),('FrontRightLeg',2.7,-1.8),('BackLeftLeg',-2.7,1.8),('BackRightLeg',2.7,1.8)]: qleg(name,x,z,3.1,'dark')
 box('Cowcatcher',(0,1.65,-4.25),(6.2,1.2,1.0),'brass',rot=(math.radians(-15),0,0),bev=.12); box('RailHammer',(0,5.4,.25),(1.5,4.0,1.7),'iron2',rot=(0,0,math.radians(90)),bev=.18)
 cyl('WheelL',(-3.4,2.0,.8),1.05,.7,'brass',rot=(0,math.radians(90),0),verts=12); cyl('WheelR',(3.4,2.0,.8),1.05,.7,'brass',rot=(0,math.radians(90),0),verts=12)
 return export('Railbreaker')
def blueflame_sentry():
 sph('Body',(0,4.0,0),(2.7,2.7,2.7),'iron',12,7); cyl('Lens',(0,4.0,-1.5),.72,.55,'blue2',rot=(math.radians(90),0,0),verts=12); torus('GuardRing',(0,4.0,0),1.65,.16,'brass',rot=(math.radians(90),0,0))
 for i,a in enumerate((0,90,180,270)): box('BladeFin'+str(i+1),(math.cos(math.radians(a))*1.85,4.0+math.sin(math.radians(a))*1.85,.15),(.35,1.5,.65),'iron2',rot=(0,0,math.radians(a)),bev=.06)
 cone('BlueFlame',(0,2.4,.3),.75,.06,2.8,'blue',verts=8)
 return export('BlueflameSentry')
def foundry_reaver():
 human_base(4.1,1.06,'iron','iron2'); box('HeadMask',(0,6.25,-.82),(1.85,1.35,.28),'dark',bev=.1); sph('EyeL',(-.48,6.3,-1.0),(.25,.25,.12),'ember',8,5); sph('EyeR',(.48,6.3,-1.0),(.25,.25,.12),'ember',8,5)
 box('ShoulderL',(-1.65,5.25,0),(1.5,1.5,1.6),'brass',rot=(0,0,math.radians(-12)),bev=.18); box('RightBlade',(1.85,3.0,-.15),(.22,3.6,.6),'iron2',rot=(0,0,math.radians(-12)),bev=.05); box('BladeEdge',(1.72,1.55,-.15),(.55,1.3,.2),'white',rot=(0,0,math.radians(-12)),bev=.03)
 box('BackBoiler',(0,.75,4.6),(1.8,1.0,2.4),'copper',bev=.18)
 return export('FoundryReaver')
def smelter_golem():
 box('Body',(0,3.3,.2),(6.2,5.0,5.2),'brick',bev=.42); box('Head',(0,6.35,-.25),(3.5,2.3,2.8),'iron',bev=.28); sph('Face',(0,6.45,-1.7),(2.4,1.3,.55),'dark',10,6); sph('Core',(0,3.4,-2.55),(2.0,2.1,.45),'ember',12,7)
 box('LeftArm',(-4.0,3.7,.1),(2.0,4.8,2.2),'iron2',rot=(0,0,math.radians(-7)),bev=.3); box('RightArm',(4.0,3.7,.1),(2.0,4.8,2.2),'iron2',rot=(0,0,math.radians(7)),bev=.3); box('LeftLeg',(-1.7,.6,.4),(2.0,3.2,2.0),'dark',bev=.25); box('RightLeg',(1.7,.6,.4),(2.0,3.2,2.0),'dark',bev=.25)
 cyl('ShoulderVatL',(-3.2,6.15,.7),1.0,2.6,'copper',verts=12); cyl('ShoulderVatR',(3.2,6.15,.7),1.0,2.6,'copper',verts=12); box('CrownStack',(0,8.3,.6),(1.5,3.2,1.5),'dark',bev=.18)
 return export('SmelterGolem')
def forge_specter():
 sph('Body',(0,4.2,0),(2.5,2.8,2.3),'ash',12,7); sph('Mask',(0,4.55,-1.25),(1.65,1.55,.5),'iron',10,6); sph('EyeL',(-.45,4.7,-1.55),(.23,.23,.12),'blue2',8,5); sph('EyeR',(.45,4.7,-1.55),(.23,.23,.12),'blue2',8,5)
 for i,a in enumerate((25,145,265)): box('ChainShard'+str(i+1),(math.cos(math.radians(a))*1.8,4.1+math.sin(math.radians(a))*1.2,.45),(1.2,.25,.35),'brass',rot=(0,0,math.radians(a)),bev=.04)
 cone('GhostTail',(0,2.0,.2),1.1,.08,4.2,'ash',verts=9); torus('Halo',(0,5.8,.2),1.5,.12,'blue',rot=(math.radians(90),0,0))
 return export('ForgeSpecter')
def ironclad_enforcer():
 human_base(4.2,1.15,'iron','dark'); box('Helmet',(0,6.55,0),(2.35,2.0,1.9),'iron2',bev=.25); box('Visor',(0,6.5,-1.02),(1.75,.55,.18),'ember',bev=.04)
 box('ChestPlate',(0,4.35,-.85),(2.7,2.55,.35),'brass',bev=.1); box('Shield',(-2.25,3.9,-.2),(2.2,3.5,.45),'iron2',bev=.22); box('Baton',(2.15,3.0,-.1),(.35,3.5,.45),'copper',rot=(0,0,math.radians(-12)),bev=.06)
 box('AuthorityMark',(0,4.7,-1.08),(.7,.7,.12),'ember',bev=.03)
 return export('IroncladEnforcer')
def molten_drake():
 sph('Body',(0,3.0,.5),(5.3,3.2,6.0),'slag',14,8); box('Head',(0,3.35,-3.55),(3.4,2.1,2.4),'iron',bev=.25)
 for name,x,z in [('FrontLeftLeg',-1.9,-1.9),('FrontRightLeg',1.9,-1.9),('BackLeftLeg',-2.0,2.0),('BackRightLeg',2.0,2.0)]: qleg(name,x,z,3.0,'iron2')
 for i,z in enumerate((-.2,1.2,2.6)): cone('BackHorn'+str(i+1),(0,5.0,z),.55,.05,2.0,'ember',rot=(math.radians(-18),0,0),verts=7)
 box('Jaw',(0,2.7,-4.6),(2.6,.65,1.1),'dark',bev=.12); sph('MouthHeat',(0,2.85,-5.05),(1.6,.55,.25),'ember',10,6); box('Tail',(0,3.1,4.15),(1.0,1.0,3.7),'slag',rot=(math.radians(-16),0,0),bev=.16)
 return export('MoltenDrake')
def bellows_titan():
 box('Body',(0,3.6,.2),(7.0,5.2,5.8),'iron',bev=.45); box('Head',(0,6.8,-.35),(3.8,2.4,2.8),'brass',bev=.28); sph('Core',(0,3.75,-2.85),(2.3,2.0,.45),'ember',12,7)
 box('LeftArm',(-4.5,3.8,0),(2.4,5.0,2.6),'dark',bev=.34); box('RightArm',(4.5,3.8,0),(2.4,5.0,2.6),'dark',bev=.34); box('LeftLeg',(-1.9,.65,.4),(2.2,3.3,2.2),'iron2',bev=.28); box('RightLeg',(1.9,.65,.4),(2.2,3.3,2.2),'iron2',bev=.28)
 # signature twin accordion bellows on back
 for side in (-1,1):
  for i in range(4): box(('BellowsL' if side<0 else 'BellowsR')+str(i+1),(side*2.4,4.0,3.15+i*.25),(2.0,.35,2.5),'cloth',bev=.05)
  cyl('ExhaustL' if side<0 else 'ExhaustR',(side*2.5,6.6,2.2),.65,3.2,'copper',verts=10)
 return export('BellowsTitan')
def belforge_sentinel():
 human_base(4.4,1.22,'dark','iron'); box('Helm',(0,6.95,.05),(2.6,2.15,2.0),'iron2',bev=.3); box('Visor',(0,6.85,-1.02),(1.95,.48,.2),'blue2',bev=.03); box('Cuirass',(0,4.55,-.95),(3.05,2.8,.4),'brass',bev=.12)
 for side in (-1,1): box('PauldronL' if side<0 else 'PauldronR',(side*1.9,5.55,0),(1.65,1.75,1.7),'iron2',rot=(0,0,math.radians(10*side)),bev=.22)
 box('LeftShield',(-2.5,4.0,-.1),(2.7,4.3,.5),'iron',bev=.25); box('RightHalberd',(2.5,3.6,-.1),(.38,5.8,.45),'dark',rot=(0,0,math.radians(-6)),bev=.06); box('HalberdHead',(2.25,6.25,-.1),(1.8,.7,.25),'brass',rot=(0,0,math.radians(-18)),bev=.08)
 sph('AuthorityCore',(0,4.65,-1.25),(.75,.75,.25),'blue2',10,6)
 return export('BelforgeSentinel')
def belforge_colossus():
 # Boss-specific giant silhouette: furnace torso, crown stacks, massive asymmetrical arms.
 human_base(5.5,1.75,'dark','iron'); box('CrownHelm',(0,9.3,.1),(4.2,2.8,3.1),'iron2',bev=.38); box('FaceFurnace',(0,9.05,-1.65),(3.1,1.5,.35),'ember',bev=.08)
 box('ChestFurnace',(0,5.85,-1.75),(4.2,4.0,.6),'brass',bev=.18); sph('ColossusCore',(0,5.85,-2.12),(2.25,2.35,.42),'ember',14,8)
 box('LeftArm',(-5.2,5.55,.1),(3.0,6.8,3.1),'iron2',rot=(0,0,math.radians(-5)),bev=.4); box('RightArm',(5.45,5.6,.1),(3.4,7.0,3.3),'iron',rot=(0,0,math.radians(5)),bev=.42)
 box('LeftLeg',(-2.0,1.0,.45),(2.65,5.0,2.6),'dark',bev=.35); box('RightLeg',(2.0,1.0,.45),(2.65,5.0,2.6),'dark',bev=.35)
 # Huge forge hammer integrated with right arm.
 box('ColossusHammerShaft',(6.4,3.0,-.2),(.65,7.5,.75),'copper',rot=(0,0,math.radians(-8)),bev=.1); box('ColossusHammerHead',(6.85,6.45,-.2),(4.4,2.0,2.3),'iron2',rot=(0,0,math.radians(-8)),bev=.3)
 for side in (-1,1):
  cyl('BackStackL' if side<0 else 'BackStackR',(side*2.2,9.8,2.1),.95,5.2,'dark',verts=12); torus('StackBandL' if side<0 else 'StackBandR',(side*2.2,10.3,2.1),1.05,.18,'brass')
 for i,x in enumerate((-2.2,0,2.2)): cone('CrownFlame'+str(i+1),(x,11.0,-.1),.65,.06,2.3,'ember',verts=8)
 return export('BelforgeColossus')

MAT=material(); builders=[rivet_scuttler,slagmite,gearjaw_hound,cindercoil,pressure_bastion,furnace_husk,arc_siphon,railbreaker,blueflame_sentry,foundry_reaver,smelter_golem,forge_specter,ironclad_enforcer,molten_drake,bellows_titan,belforge_sentinel,belforge_colossus]
out={}
for fn in builders:
 clear(); r=fn(); out[Path(r['file']).stem]=r
(OUT/'manifest.json').write_text(json.dumps(out,indent=2)); print(json.dumps(out,indent=2))
