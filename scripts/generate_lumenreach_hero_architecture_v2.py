#!/usr/bin/env python3
# Run with: blender --background --python scripts/generate_lumenreach_hero_architecture_v2.py
import bpy, math, json, struct, zlib, binascii
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'original'/'lumenreach_hero_architecture_v2'
OUT.mkdir(parents=True, exist_ok=True)
PALETTE={
 'timber':(0.22,0.12,0.065,1),'oak':(0.42,0.26,0.13,1),'plaster':(0.37,0.46,0.34,1),
 'warm':(0.49,0.39,0.25,1),'violet':(0.31,0.27,0.41,1),'roof':(0.065,0.15,0.13,1),
 'roof2':(0.11,0.23,0.19,1),'stone':(0.27,0.31,0.29,1),'metal':(0.32,0.35,0.34,1),
 'lumen':(0.14,0.90,0.62,1),'glass':(0.12,0.58,0.55,1),'herb':(0.19,0.48,0.26,1),
 'cloth':(0.25,0.49,0.36,1),'gold':(0.65,0.46,0.16,1),'dark':(0.10,0.105,0.10,1),
}
KEYS=list(PALETTE); GRID=4; CELL=16; ATLAS=OUT/'hero_palette.png'; M={}
def png():
 w=h=GRID*CELL; rows=[]
 for y in range(h):
  row=bytearray([0]); cy=y//CELL
  for x in range(w):
   i=cy*GRID+x//CELL; c=PALETTE[KEYS[i]][:3] if i<len(KEYS) else (1,0,1)
   row.extend(max(0,min(255,round(v*255))) for v in c)
  rows.append(bytes(row))
 raw=b''.join(rows)
 def ch(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',binascii.crc32(t+d)&0xffffffff)
 ATLAS.write_bytes(b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+ch(b'IDAT',zlib.compress(raw,9))+ch(b'IEND',b''))
def mat(k):
 n='EL2_'+k
 m=bpy.data.materials.get(n)
 if m:return m
 m=bpy.data.materials.new(n);m.diffuse_color=PALETTE[k];return m
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def box(n,loc,dims,k,rot=(0,0,0),bev=.08):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot);o=bpy.context.object;o.name=n;o.dimensions=dims
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bev:
  md=o.modifiers.new('edge','BEVEL');md.width=bev;md.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=md.name)
 o.data.materials.append(mat(k));return o
def cyl(n,loc,r,d,k,verts=10,rot=(0,0,0)):
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d,location=loc,rotation=rot);o=bpy.context.object;o.name=n;o.data.materials.append(mat(k));return o
def cone(n,loc,r1,r2,d,k,verts=8,rot=(0,0,0)):
 bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=d,location=loc,rotation=rot);o=bpy.context.object;o.name=n;o.data.materials.append(mat(k));return o
def prism_roof(n,loc,w,d,z0,ridge,k,axis='x'):
 # roof ridge along depth by default. For axis z-like alternative, rotate 90 yaw.
 hw=w/2;hd=d/2
 verts=[(-hw,-hd,z0),(hw,-hd,z0),(0,-hd,z0+ridge),(-hw,hd,z0),(hw,hd,z0),(0,hd,z0+ridge)]
 faces=[(0,1,2),(3,5,4),(0,3,4,1),(1,4,5,2),(2,5,3,0)]
 me=bpy.data.meshes.new(n+'Mesh');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o);o.location=loc
 if axis=='z':o.rotation_euler[2]=math.radians(90)
 o.data.materials.append(mat(k));return o
def arch_frame(n,x,y,z,w,h,depth=.35,k='timber'):
 box(n+'L',(x-w/2,y,z+h/2),(0.35,depth,h),k);box(n+'R',(x+w/2,y,z+h/2),(0.35,depth,h),k);box(n+'T',(x,y,z+h),(w+.35,depth,.35),k)
def window(n,x,y,z,w=1.7,h=2.6,k='glass'):
 box(n,(x,y,z),(w,.12,h),k,bev=.02);arch_frame(n+'Frame',x,y-.06,z-h/2,w+.4,h+.4,.20,'timber')
def door(n,x,y,z,w=2.6,h=4.4,k='oak'):
 box(n,(x,y,z+h/2),(w,.18,h),k);arch_frame(n+'Frame',x,y-.08,z,w+.5,h+.4,.28,'timber')
def post(n,x,y,z,h,k='timber',s=.45):box(n,(x,y,z+h/2),(s,s,h),k)
def beam(n,x,y,z,l,k='timber',axis='x',s=.38):
 dims=(l,s,s) if axis=='x' else (s,s,l) if axis=='z' else (s,l,s);box(n,(x,y,z),dims,k)
def stair(n,center,w,steps,dir=1):
 x,y,z=center
 for i in range(steps):
  box(n+str(i),(x,y-dir*i*.8,z+i*.22),(w,1.0,.44),'stone',bev=.05)
def join_export(name):
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
 bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 # material atlas by face material name
 png();im=bpy.data.images.load(str(ATLAS),check_existing=True);am=bpy.data.materials.get('EL2_HeroAtlas') or bpy.data.materials.new('EL2_HeroAtlas');am.use_nodes=True
 nodes=am.node_tree.nodes;links=am.node_tree.links;bsdf=nodes.get('Principled BSDF');tex=next((n for n in nodes if n.bl_idname=='ShaderNodeTexImage'),None) or nodes.new('ShaderNodeTexImage');tex.image=im;tex.interpolation='Closest';links.new(tex.outputs['Color'],bsdf.inputs['Base Color']);bsdf.inputs['Roughness'].default_value=.72
 slots=[s.material.name if s.material else '' for s in o.material_slots];uv=o.data.uv_layers.get('UVMap') or o.data.uv_layers.new(name='UVMap')
 for poly in o.data.polygons:
  nm=slots[poly.material_index].replace('EL2_','');idx=KEYS.index(nm) if nm in KEYS else 2;u=(idx%GRID+.5)/GRID;v=1-(idx//GRID+.5)/GRID
  for li in poly.loop_indices:uv.data[li].uv=(u,v)
  poly.material_index=0
 o.data.materials.clear();o.data.materials.append(am)
 path=OUT/(name+'.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_materials='EXPORT')
 tris=sum(max(0,len(p.vertices)-2) for p in o.data.polygons);return {'file':str(path.relative_to(ROOT)),'triangles':tris,'vertices':len(o.data.vertices)}

def civic():
 # U-shaped council complex, strong central tower and enclosed forecourt.
 box('Plinth',(0,0,.65),(40,29,1.3),'stone',bev=.16)
 box('MainHall',(0,4,6.2),(22,15,10.6),'plaster');prism_roof('MainHallRoof',(0,4,0),24,17,11.5,7.8,'roof')
 box('WestWing',(-15,-1,4.9),(9,20,8.0),'warm');prism_roof('WestWingRoof',(-15,-1,0),10.5,21.5,9.1,4.8,'roof2')
 box('EastWing',(15,-1,4.9),(9,20,8.0),'warm');prism_roof('EastWingRoof',(15,-1,0),10.5,21.5,9.1,4.8,'roof2')
 # central lantern tower
 box('Tower',(0,-7,9.3),(9,9,17),'violet');cone('TowerRoof',(0,-7,20.1),6.4,1.1,5.0,'roof',8);cyl('LumenLantern',(0,-7,17.8),1.3,3.2,'lumen',8)
 stair('CouncilSteps',(0,-15,.22),10,5,1);door('GrandDoor',0,-11.55,1.3,3.6,5.2)
 for x in (-7,7):window('FrontWindow'+str(x),x,-3.55,7.0,2.2,3.0)
 for x in (-15,15):
  for zz in (-6,2,6):window('WingWindow'+str(x)+str(zz),x,zz-11 if False else -11.05,4.8,1.6,2.4)
 # forecourt colonnade / buttresses
 for x in (-19,-12,12,19):post('CourtPost'+str(x),x,-12,1.3,6.5,'timber',.55)
 beam('CourtBeam',0,-12,7.6,39,'timber','x',.42)
 box('Banner',(0,-12.2,10.1),(5.8,.18,4.0),'gold',bev=.03)
 return join_export('LumenCivicHallV2')

def depot():
 # Long asymmetrical warehouse with loading dock, crane and clerestory.
 box('StoneBase',(0,0,.55),(37,24,1.1),'stone');box('Warehouse',(-4,1,5.0),(25,20,8.8),'warm');prism_roof('WarehouseRoof',(-4,1,0),27,22,9.5,5.4,'roof')
 box('Office',(12,-3,4.3),(10,12,7.2),'plaster');prism_roof('OfficeRoof',(12,-3,0),11,13,8.2,4.0,'roof2')
 box('LoadingDock',(-4,-12.8,1.2),(30,5.5,1.0),'oak');box('Canopy',(-4,-14.3,7.4),(31,6.0,.5),'roof2',rot=(math.radians(5),0,0))
 for x in (-16,-7,2,11):post('DockPost'+str(x),x,-15.3,1.3,6.2,'timber',.42)
 # crane silhouette
 post('CraneMast',17,8,1.1,12,'timber',.7);beam('CraneBoom',10,8,12.6,15,'timber','x',.65);cyl('Hoist',(3.2,8,10.8),1.0,.6,'metal',12,rot=(math.radians(90),0,0))
 for x in (-11,-3,5):window('Clerestory'+str(x),x,11.05,7.1,2.0,1.5)
 door('DepotDoor',-2,-9.1,1.1,4.2,5.0)
 return join_export('LumenQuartermasterDepotV2')

def archive():
 # Rotunda + reading wing + beacon spire.
 cyl('Rotunda',(0,2,5.0),9.3,8.8,'violet',10);cone('RotundaRoof',(0,2,12.1),10.6,2.0,5.4,'roof',10)
 box('ReadingWing',(-12,-2,4.5),(16,12,7.8),'plaster');prism_roof('ReadingRoof',(-12,-2,0),17.5,13.5,8.7,4.6,'roof2')
 box('ArchiveStack',(10,-3,5.5),(8,10,10),'warm');cone('StackRoof',(10,-3,12.4),5.6,1.4,4.0,'roof',8)
 cyl('BeaconCore',(0,2,16.0),1.1,5.0,'lumen',8);cone('BeaconCap',(0,2,19.5),2.2,.2,2.0,'metal',8)
 stair('ArchiveSteps',(0,-9.8,.22),7,4,1);door('ArchiveDoor',0,-7.35,1.1,2.8,4.8)
 for ang in range(0,360,72):
  a=math.radians(ang);x=math.sin(a)*8.9;y=2-math.cos(a)*8.9;cyl('RotundaButtress'+str(ang),(x,y,4.2),.45,7.0,'timber',6)
 for x in (-16,-10,-4):window('ReadWin'+str(x),x,-8.05,5.0,1.8,2.8)
 return join_export('LumenArchiveLodgeV2')

def inn():
 # L-shaped two-storey inn with balcony and corner stair tower.
 box('MainBlock',(-4,2,6.0),(26,18,11),'plaster');prism_roof('MainRoof',(-4,2,0),28,20,12.0,6.0,'roof')
 box('TavernWing',(11,-5,4.6),(14,12,8.2),'warm');prism_roof('TavernRoof',(11,-5,0),15.5,13.5,9.4,4.5,'roof2')
 cyl('CornerTower',(-16,-5,6.0),5.0,10.5,'violet',8);cone('CornerRoof',(-16,-5,13.5),6.2,.8,5.0,'roof',8)
 box('Balcony',(-2,-9.5,7.8),(22,3.5,.6),'oak');
 for x in (-11,-4,3,8):post('BalPost'+str(x),x,-10.6,1.2,6.7,'timber',.35)
 beam('BalRail',-2,-11,9.0,22,'timber','x',.3)
 door('InnDoor',5,-10.1,1.1,3.0,4.8)
 for x in (-9,-2,5):window('Upper'+str(x),x,-7.05,8.5,1.9,2.4)
 box('Sign',(12.5,-11.5,7.6),(3.5,.2,2.2),'gold');post('SignPost',14,-11.5,1.1,9,'timber',.4)
 box('Chimney',(0,7,13.0),(2.0,2.0,8.0),'stone');box('ChimneyCap',(0,7,17.1),(2.6,2.6,.6),'stone')
 return join_export('LumenWayfarerInnV2')

def healer():
 # Courtyard apothecary with greenhouse and herb drying gallery.
 box('ApothMain',(-5,2,4.7),(19,15,8.4),'plaster');prism_roof('ApothRoof',(-5,2,0),21,17,9.3,5.0,'roof2')
 box('Greenhouse',(9,3,3.4),(9,13,5.6),'glass');prism_roof('GlassRoof',(9,3,0),10,14,6.4,3.6,'glass')
 box('HerbGallery',(0,-8.2,1.4),(24,4.5,.5),'oak');box('GalleryRoof',(0,-9.2,6.8),(25,5.2,.4),'cloth',rot=(math.radians(6),0,0))
 for x in (-10,-3,4,10):post('HerbPost'+str(x),x,-10.4,1.1,5.7,'timber',.32)
 for x in (-8,-4,0,4,8):cyl('HerbBundle'+str(x),(x,-9.7,4.7),.35,1.7,'herb',6)
 door('HealerDoor',-5,-5.55,1.1,2.6,4.3)
 cyl('MortarSign',(7,-9.5,6.0),1.0,.25,'lumen',10,rot=(math.radians(90),0,0))
 return join_export('LumenHealerLodgeV2')

def workshop():
 # Open smithy/workshop with clerestory, forge stack and side tool shed.
 box('WorkshopSlab',(0,0,.5),(28,22,1),'stone');
 for x in (-12,-4,4,12):post('MainPost'+str(x),x,0,1,9,'timber',.55)
 prism_roof('HighRoof',(0,0,0),30,24,10.0,7.0,'roof')
 box('BackWall',(0,10.2,5.1),(28,.6,8.2),'warm');box('ToolShed',(-10,4,3.8),(8,10,6.6),'plaster');prism_roof('ToolRoof',(-10,4,0),9,11,7.3,3.8,'roof2')
 box('Forge',(7,5,2.8),(7,5,4.5),'dark');box('ForgeGlow',(7,2.4,2.6),(5.5,.2,1.5),'lumen');box('ForgeStack',(8,6,12.5),(2.4,2.4,14),'stone')
 box('WorkBench',(5,-5.5,2.0),(10,2.3,1.4),'oak');box('ToolRack',(-7,-8,4.6),(10,.5,6.0),'timber')
 return join_export('LumenCraftWorkshopV2')

def stable():
 # U-shaped working stable with open central yard and hay loft.
 box('RearBarn',(0,8,5.2),(28,10,9.0),'warm');prism_roof('RearRoof',(0,8,0),30,12,10.0,5.5,'roof')
 box('WestStall',(-11,-1,3.6),(7,15,6.2),'oak');prism_roof('WestRoof',(-11,-1,0),8,16,7.2,3.5,'roof2')
 box('EastStall',(11,-1,3.6),(7,15,6.2),'oak');prism_roof('EastRoof',(11,-1,0),8,16,7.2,3.5,'roof2')
 box('LoftFace',(0,2.8,8.0),(12,.5,4.5),'plaster');window('LoftWindow',0,2.45,8.0,2.4,2.4)
 for x in (-12,-8,8,12):post('YardPost'+str(x),x,-8.2,1.0,5.0,'timber',.38)
 beam('YardBeam',0,-8.2,5.8,25,'timber','x',.4)
 box('HayBaleL',(-5,5.5,2),(4,3,2.4),'gold');box('HayBaleR',(5,5.5,2),(4,3,2.4),'gold')
 return join_export('LumenOpenStableV2')

def proving():
 # Long oath hall with open training porch and asymmetric watch loft.
 box('Hall',(0,3,5.0),(28,16,9),'plaster');prism_roof('HallRoof',(0,3,0),30,18,10.0,6.2,'roof')
 box('WatchLoft',(11,-4,7.0),(9,9,13),'violet');cone('WatchRoof',(11,-4,15.8),6.0,1.0,4.5,'roof2',8)
 box('TrainingPorch',(-5,-8.5,1.2),(22,6,.6),'oak');box('PorchRoof',(-5,-9.2,7.5),(23,7,.45),'cloth',rot=(math.radians(5),0,0))
 for x in (-15,-8,-1,5):post('TrialPost'+str(x),x,-11.3,1.2,6.2,'timber',.4)
 door('OathDoor',2,-5.1,1.1,3.0,4.8)
 box('OathBanner',(-7,-5.5,7.6),(4.0,.16,5.2),'gold');cyl('OathLumen',(-7,-5.65,9.0),.65,2.0,'lumen',8,rot=(math.radians(90),0,0))
 return join_export('LumenProvingLodgeV2')

M={k:mat(k) for k in KEYS}
results={}
for fn in (civic,depot,archive,inn,healer,workshop,stable,proving):
 clear();r=fn();results[Path(r['file']).stem]=r
(OUT/'manifest.json').write_text(json.dumps(results,indent=2))
print(json.dumps(results,indent=2))
