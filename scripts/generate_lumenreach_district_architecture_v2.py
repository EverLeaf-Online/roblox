#!/usr/bin/env python3
# Original EverLeaf district architecture V2. Each asset has role-specific massing.
import bpy, math, json, struct, zlib, binascii
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'original'/'lumenreach_district_architecture_v2'; OUT.mkdir(parents=True, exist_ok=True)
PAL={
 'timber':(0.21,0.13,0.08,1),'timber2':(0.42,0.27,0.15,1),'stone':(0.25,0.30,0.28,1),
 'plaster':(0.38,0.46,0.35,1),'moss':(0.31,0.49,0.25,1),'roof':(0.08,0.18,0.16,1),
 'roof2':(0.13,0.25,0.20,1),'lumen':(0.17,0.92,0.68,1),'water':(0.13,0.58,0.61,1),
 'cloth':(0.42,0.31,0.18,1),'bone':(0.63,0.65,0.57,1),'violet':(0.34,0.29,0.44,1)
}
KEYS=list(PAL); GRID=4; CELL=16; ATLAS=OUT/'district_palette.png'; M={}
def png():
 w=h=GRID*CELL; rows=[]
 for y in range(h):
  row=bytearray([0]); cy=y//CELL
  for x in range(w):
   i=cy*GRID+x//CELL; c=PAL[KEYS[i]][:3] if i<len(KEYS) else (1,0,1); row.extend(round(v*255) for v in c)
  rows.append(bytes(row))
 def ch(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',binascii.crc32(t+d)&0xffffffff)
 ATLAS.write_bytes(b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+ch(b'IDAT',zlib.compress(b''.join(rows),9))+ch(b'IEND',b''))
def mats():
 for k,c in PAL.items():
  m=bpy.data.materials.new('EL_'+k); m.diffuse_color=c; m.use_nodes=True; bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=c; bs.inputs['Roughness'].default_value=.74; M[k]=m
def clear(): bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def box(n,loc,dims,mat='timber',rot=(0,0,0),bev=.08):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot); o=bpy.context.object; o.name=n; o.dimensions=dims; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bev:
  md=o.modifiers.new('edge','BEVEL'); md.width=bev; md.segments=1; bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=md.name)
 o.data.materials.append(M[mat]); return o
def cyl(n,loc,r,d,mat='stone',verts=10,rot=(0,0,0)):
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d,location=loc,rotation=rot); o=bpy.context.object; o.name=n; o.data.materials.append(M[mat]); return o
def cone(n,loc,r1,r2,d,mat='roof',verts=8):
 bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=d,location=loc); o=bpy.context.object; o.name=n; o.data.materials.append(M[mat]); return o
def gable(n,loc,w,d,z0,h,mat='roof'):
 x=w/2; y=d/2; vs=[(-x,-y,z0),(x,-y,z0),(0,-y,z0+h),(-x,y,z0),(x,y,z0),(0,y,z0+h)]; fs=[(0,1,2),(3,5,4),(0,3,4,1),(1,4,5,2),(2,5,3,0)]
 me=bpy.data.meshes.new(n+'Mesh'); me.from_pydata(vs,[],fs); me.update(); o=bpy.data.objects.new(n,me); bpy.context.collection.objects.link(o); o.location=loc; o.data.materials.append(M[mat]); return o
def wall_frame(cx,cy,z,w,h):
 for x in (-w/2,w/2): box('Post',(cx+x,cy,z+h/2),(.35,.4,h),'timber')
 box('Beam',(cx,cy,z+h),(w+.35,.4,.35),'timber')
def join_export(name):
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH']; bpy.ops.object.select_all(action='DESELECT'); [o.select_set(True) for o in objs]; bpy.context.view_layer.objects.active=objs[0]; bpy.ops.object.join(); o=bpy.context.object; o.name=name
 # bake material ids to texture atlas UV points
 png(); img=bpy.data.images.load(str(ATLAS),check_existing=True); m=bpy.data.materials.get('EL_DistrictAtlas') or bpy.data.materials.new('EL_DistrictAtlas'); m.use_nodes=True; bs=m.node_tree.nodes.get('Principled BSDF'); tex=next((n for n in m.node_tree.nodes if n.type=='TEX_IMAGE'),None) or m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=img; tex.interpolation='Closest';
 try: m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
 except: pass
 slots=[s.material.name if s.material else '' for s in o.material_slots]; uv=o.data.uv_layers.get('UVMap') or o.data.uv_layers.new(name='UVMap')
 for poly in o.data.polygons:
  nm=slots[poly.material_index].replace('EL_',''); key=nm if nm in KEYS else 'plaster'; i=KEYS.index(key); u=(i%GRID+.5)/GRID; v=1-(i//GRID+.5)/GRID
  for li in poly.loop_indices: uv.data[li].uv=(u,v)
  poly.material_index=0
 o.data.materials.clear(); o.data.materials.append(m); bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 path=OUT/(name+'.glb'); bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_apply=True,export_materials='EXPORT')
 tris=sum(len(p.vertices)-2 for p in o.data.polygons); return {'file':str(path.relative_to(ROOT)),'triangles':tris,'vertices':len(o.data.vertices)}
def wayhouse():
 # roadside L-plan with covered traveler porch and rear chimney
 box('Main',(0,2,5),(18,12,8),'plaster'); gable('Roof',(0,2,0),20,14,9,5,'roof'); box('Wing',(8,-7,4),(10,8,6),'plaster'); gable('WingRoof',(8,-7,0),11,9,7,4,'roof2'); box('Porch',(0,-7,1),(15,5,.6),'timber2'); wall_frame(0,-9,1,14,6); box('PorchRoof',(0,-7.5,7),(16,6,.45),'roof2',rot=(math.radians(8),0,0)); box('Chimney',(-6,5,8),(2,2,12),'stone'); return join_export('LumenRoadWayhouseV2')
def barn():
 box('Barn',(0,0,5),(22,15,9),'timber2'); gable('BarnRoof',(0,0,0),25,18,10,7,'roof'); box('Doors',(0,-7.7,4),(8,.45,7),'timber'); box('HayLoft',(0,-7.9,8),(5,.35,3),'cloth'); box('LeanTo',(13,2,3),(7,12,5),'timber'); box('LeanRoof',(13,2,6),(8,13,.4),'roof2',rot=(0,math.radians(-12),0)); return join_export('LumenFarmBarnV2')
def croft_a():
 box('House',(0,0,4),(14,11,7),'plaster'); gable('Roof',(0,0,0),16,13,8,5,'roof'); box('StoneEnd',(-7,0,4),(2,10,7),'stone'); box('Porch',(3,-7,1),(9,4,.5),'timber2'); box('PorchRoof',(3,-7,5),(10,5,.35),'roof2',rot=(math.radians(10),0,0)); return join_export('LumenCroftCottageAV2')
def croft_b():
 box('House',(0,1,4),(13,10,7),'plaster'); gable('Roof',(0,1,0),15,12,8,4.5,'roof2'); box('RoundKitchen',(7,-3,3.5),(6,7,6),'plaster'); cone('KitchenRoof',(7,-3,8),4.3,.4,4,'roof',8); box('FrontBay',(-5,-6,3),(5,4,5),'timber2'); return join_export('LumenCroftCottageBV2')
def stilt():
 # long wetland cabin raised on piles with split roof and dock landing
 for x in (-7,-2,3,8):
  for y in (-4,4): cyl('Pile',(x,y,2),.35,4,'timber',8)
 box('Deck',(0,0,4),(19,11,.6),'timber2'); box('Cabin',(-2,0,8),(14,9,7),'plaster'); gable('CabinRoof',(-2,0,0),16,11,11.5,5,'roof2'); box('OpenDeck',(8,0,5),(6,10,.4),'timber2'); box('Dock',(12,0,4),(10,4,.45),'timber2'); box('ReedAwning',(8,-3,9),(7,5,.35),'cloth',rot=(math.radians(8),0,0)); return join_export('LumenGlowmereStiltHouseV2')
def ranger():
 box('Hall',(0,2,5),(22,13,8),'timber2'); gable('HallRoof',(0,2,0),24,15,9,7,'roof'); box('WatchWing',(-12,-2,7),(7,8,12),'stone'); cone('WatchRoof',(-12,-2,14),5.1,.4,5,'roof2',8); box('OpenArmsRack',(10,-7,4),(8,5,6),'timber'); box('RackRoof',(10,-7,7.5),(9,6,.35),'roof2'); return join_export('LumenMossglenRangerHallV2')
def gatehouse():
 box('LeftTower',(-11,0,8),(8,10,15),'stone'); box('RightTower',(11,0,8),(8,10,15),'stone'); cone('LeftRoof',(-11,0,17),5.6,.5,5,'roof',8); cone('RightRoof',(11,0,17),5.6,.5,5,'roof',8); box('Bridge',(0,0,13),(15,8,5),'plaster'); box('GateLintel',(0,-4.5,10),(14,1,4),'timber2'); box('GateDoor',(0,-4.8,5),(9,.6,10),'timber'); return join_export('LumenFrontierGatehouseV2')
def ruined():
 box('WallA',(-5,0,4),(10,2,8),'stone'); box('WallB',(4,4,3),(2,10,6),'stone'); box('BrokenTower',(-8,5,6),(6,6,12),'stone'); box('RoofShard',(1,-2,9),(9,6,.5),'roof',rot=(0,math.radians(18),math.radians(10))); box('ArchLintel',(4,-1,7),(7,2,2),'stone'); return join_export('LumenRuinedHallV2')
def forge():
 box('ForgeHall',(-4,2,5),(18,13,8),'stone'); gable('ForgeRoof',(-4,2,0),20,15,9,6,'roof'); box('OpenSmithy',(10,-1,4),(10,12,7),'timber2'); box('SmithyRoof',(10,-1,8),(11,13,.4),'roof2',rot=(0,math.radians(-8),0)); box('Chimney',(-8,4,11),(3,3,18),'stone'); cyl('ForgeBasin',(8,-3,2),3,1.5,'lumen',12); return join_export('LumenForgeYardV2')
def mausoleum():
 box('Crypt',(0,2,5),(18,14,9),'stone'); gable('CryptRoof',(0,2,0),20,16,10,5,'bone'); box('Entry',(0,-7,4),(8,5,7),'stone'); gable('EntryRoof',(0,-7,0),9,6,8,4,'bone'); forx=[-6,6]
 for x in forx: cyl('Spire',(x,6,11),1.2,8,'bone',8); cone('SpireCap',(x,6,16),1.8,.1,3,'roof2',8)
 return join_export('LumenGraveboneMausoleumV2')
def observatory():
 cyl('Base',(0,0,5),8,9,'stone',12); cone('Dome',(0,0,12),8.4,1.2,6,'violet',12); cyl('LensTower',(10,1,8),4,13,'plaster',10); cone('LensRoof',(10,1,16),4.6,.3,4,'roof2',10); box('Bridge',(5,1,9),(8,4,3),'timber2'); cyl('Beacon',(10,1,19),1,5,'lumen',8); return join_export('LumenSunmossObservatoryV2')
def sanctuary():
 # open hex sanctuary with stepped terraces and central lumen spire
 box('Terrace',(0,0,1),(30,24,2),'stone'); box('Upper',(0,2,3),(22,16,2),'stone');
 for x in (-9,0,9):
  for y in (-5,7): cyl('Column',(x,y,8),1.1,10,'stone',8)
 box('Canopy',(0,1,14),(24,17,1),'roof2'); cone('CanopyTop',(0,1,17),13,3,5,'roof',8); cyl('LumenSpire',(0,1,14),1.3,18,'lumen',8); return join_export('LumenVeilfallSanctuaryV2')
def fortress():
 box('Tower',(0,0,10),(14,14,19),'stone'); box('Battlement',(0,0,20),(16,16,2),'stone');
 for x in (-6,6):
  for y in (-6,6): box('Merlon',(x,y,22),(3,3,4),'stone')
 box('BrokenWing',(11,5,6),(10,9,11),'stone',rot=(0,math.radians(-8),0)); box('Banner',(0,-7.3,12),(5,.25,8),'cloth'); return join_export('LumenShatteredFortressTowerV2')
def shrine():
 box('Steps',(0,0,1),(12,10,2),'stone'); box('Plinth',(0,0,3),(8,7,3),'stone'); cyl('Pillar',(0,0,8),1.4,9,'stone',8); cone('Cap',(0,0,14),3.8,.3,5,'roof2',8); cyl('LumenCore',(0,0,11),.8,4,'lumen',8); return join_export('LumenStoneShrineV2')
if __name__=='__main__':
 mats(); out={}
 for fn in [wayhouse,barn,croft_a,croft_b,stilt,ranger,gatehouse,ruined,forge,mausoleum,observatory,sanctuary,fortress,shrine]:
  clear(); r=fn(); out[Path(r['file']).stem]=r
 (OUT/'manifest.json').write_text(json.dumps(out,indent=2)); print(json.dumps(out,indent=2))
