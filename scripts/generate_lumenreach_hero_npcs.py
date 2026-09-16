#!/usr/bin/env python3
# Original EverLeaf hero NPC visual meshes. Roblox R15 bones are supplied at runtime;
# these are authored visual shells/accessories aligned to the standard R15 body layout.
import bpy, json, struct, zlib, binascii, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'assets'/'original'/'lumenreach_hero_npcs'; OUT.mkdir(parents=True,exist_ok=True)
PAL={
 'skin':(0.78,0.58,0.42,1),'skin2':(0.62,0.43,0.30,1),'green':(0.18,0.35,0.25,1),'green2':(0.30,0.50,0.34,1),
 'brown':(0.25,0.16,0.10,1),'leather':(0.39,0.24,0.13,1),'cream':(0.58,0.55,0.43,1),'blue':(0.18,0.38,0.48,1),
 'violet':(0.34,0.27,0.48,1),'gold':(0.58,0.41,0.16,1),'dark':(0.10,0.12,0.11,1),'lumen':(0.18,0.95,0.68,1)
}
KEYS=list(PAL); GRID=4; CELL=16; ATLAS=OUT/'npc_palette.png'; M={}
def write_png():
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
  m=bpy.data.materials.new('EL_'+k); m.diffuse_color=c; m.use_nodes=True; bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=c; bs.inputs['Roughness'].default_value=.72; M[k]=m
def clear(): bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def box(name,loc,dims,mat,bev=.10,rot=(0,0,0)):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot); o=bpy.context.object; o.name=name; o.dimensions=dims; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bev:
  md=o.modifiers.new('soft','BEVEL'); md.width=bev; md.segments=1; bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=md.name)
 o.data.materials.append(M[mat]); return o
def sphere(name,loc,dims,mat):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=loc); o=bpy.context.object; o.name=name; o.scale=(dims[0]/2,dims[1]/2,dims[2]/2); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(M[mat]); return o
def cyl(name,loc,r,d,mat,rot=(0,0,0),verts=10):
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d,location=loc,rotation=rot); o=bpy.context.object; o.name=name; o.data.materials.append(M[mat]); return o
# Standard visual segment centers, Z-up Blender. Runtime aligns each named segment to hidden R15 equivalent.
SEG={
 'Head':((0,0,7.15),(2.0,1.8,2.0)),'UpperTorso':((0,0,5.35),(2.25,1.25,2.1)),'LowerTorso':((0,0,3.85),(2.0,1.15,1.25)),
 'LeftUpperArm':((-1.65,0,5.35),(1.0,1.0,2.1)),'RightUpperArm':((1.65,0,5.35),(1.0,1.0,2.1)),
 'LeftLowerArm':((-1.65,0,3.85),(0.9,.9,1.8)),'RightLowerArm':((1.65,0,3.85),(.9,.9,1.8)),
 'LeftHand':((-1.65,0,2.65),(.85,.85,.85)),'RightHand':((1.65,0,2.65),(.85,.85,.85)),
 'LeftUpperLeg':((-.62,0,2.35),(.95,1.0,2.1)),'RightUpperLeg':((.62,0,2.35),(.95,1.0,2.1)),
 'LeftLowerLeg':((-.62,0,.95),(.85,.9,1.8)),'RightLowerLeg':((.62,0,.95),(.85,.9,1.8)),
 'LeftFoot':((-.62,-.25,-.05),(.9,1.45,.55)),'RightFoot':((.62,-.25,-.05),(.9,1.45,.55)),
}
def base_body(cloth='green',accent='green2',skin='skin',build=1.0):
 for n,(loc,d) in SEG.items():
  mat=skin if n in ('Head','LeftHand','RightHand') else cloth
  if 'Leg' in n or 'Foot' in n: mat='dark'
  dims=(d[0]*build,d[1]*build,d[2])
  if n=='Head': sphere(n,loc,dims,mat)
  else: box(n,loc,dims,mat,.10)
 # tunic overlay gives silhouette without changing rig anchors
 box('UpperTorso_Tunic',(0,-.03,4.65),(2.65*build,1.45,3.25),accent,.12)
def hair(style='short',mat='brown'):
 if style=='long':
  sphere('Head_HairCap',(0,.08,7.55),(2.15,1.95,1.35),mat); box('Head_HairBack',(0,.55,6.65),(1.75,.45,2.4),mat,.15)
 elif style=='bun':
  sphere('Head_HairCap',(0,.05,7.55),(2.12,1.9,1.2),mat); sphere('Head_HairBun',(0,.75,7.8),(.9,.9,.9),mat)
 elif style=='hood':
  sphere('Head_Hood',(0,.05,7.25),(2.4,2.15,2.35),mat)
 else: sphere('Head_HairCap',(0,.08,7.55),(2.1,1.9,1.15),mat)
def export(name):
 write_png(); atlas=bpy.data.materials.get('EL_NpcAtlas') or bpy.data.materials.new('EL_NpcAtlas'); atlas.use_nodes=True; img=bpy.data.images.load(str(ATLAS),check_existing=True); bs=atlas.node_tree.nodes.get('Principled BSDF'); tex=next((n for n in atlas.node_tree.nodes if n.type=='TEX_IMAGE'),None) or atlas.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=img; tex.interpolation='Closest'
 try: atlas.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
 except: pass
 # IMPORTANT: keep objects separate; bake each object's single material to an atlas point.
 for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
  key=(o.data.materials[0].name.replace('EL_','') if o.data.materials else 'green'); key=key if key in KEYS else 'green'; i=KEYS.index(key); u=(i%GRID+.5)/GRID; v=1-(i//GRID+.5)/GRID; uv=o.data.uv_layers.get('UVMap') or o.data.uv_layers.new(name='UVMap')
  for poly in o.data.polygons:
   for li in poly.loop_indices: uv.data[li].uv=(u,v)
   poly.material_index=0
  o.data.materials.clear(); o.data.materials.append(atlas)
 path=OUT/(name+'.glb'); bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_apply=True,export_materials='EXPORT')
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH']; return {'file':str(path.relative_to(ROOT)),'parts':[o.name for o in objs],'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objs)}
def ilyra():
 base_body('green','green2','skin',.94); hair('long','brown'); box('UpperTorso_Cape',(-.35,.55,5.25),(2.75,.35,2.9),'green2',.08,rot=(math.radians(-6),0,math.radians(7))); box('UpperTorso_Satchel',(.8,-.72,4.75),(1.0,.55,1.25),'leather'); box('Head_ScarfTail',(-.85,.35,6.65),(.45,.35,2.1),'gold',.06,rot=(0,math.radians(-18),0)); return export('IlyraWayfarerGuide')
def orin():
 base_body('brown','cream','skin2',1.12); hair('short','dark'); box('UpperTorso_Apron',(0,-.72,4.6),(2.45,.28,3.25),'cream',.05); box('LowerTorso_Belt',(0,-.62,3.95),(2.45,.35,.55),'leather',.05); box('LowerTorso_Pouch',(-1.15,-.6,3.55),(.85,.5,1.0),'leather',.08); box('LowerTorso_Pouch2',(1.15,-.6,3.55),(.85,.5,1.0),'leather',.08); return export('OrinQuartermaster')
def tovin():
 base_body('green','dark','skin',.92); hair('hood','green'); box('UpperTorso_ShoulderGuard',(-1.2,-.15,5.75),(1.2,1.5,.65),'leather',.12,rot=(0,0,math.radians(-12))); box('UpperTorso_Quiver',(1.0,.8,5.1),(1.0,.65,3.0),'brown',.08,rot=(math.radians(8),0,math.radians(12))); cyl('UpperTorso_ArrowBundle',(1.0,.85,6.6),.38,2.4,'gold',rot=(0,0,0),verts=8); return export('TovinMossglenScout')
def maela():
 base_body('violet','cream','skin',.90); hair('bun','brown'); box('UpperTorso_Robe',(0,-.05,4.35),(2.75,1.5,3.9),'violet',.12); box('LeftHand_Book',(-1.65,-.45,2.55),(1.35,.45,1.75),'gold',.06,rot=(math.radians(15),0,math.radians(-8))); box('Head_Glasses',(-.48,-.93,7.18),(.7,.12,.42),'gold',.03); box('Head_Glasses2',(.48,-.93,7.18),(.7,.12,.42),'gold',.03); return export('MaelaArchiveKeeper')
def seren():
 base_body('dark','green2','skin2',1.02); hair('long','dark'); box('UpperTorso_Mantle',(0,.05,5.75),(3.2,1.65,.8),'green2',.14); box('UpperTorso_LongCoat',(0,.45,4.2),(2.5,.45,4.2),'dark',.08); cyl('RightHand_Staff',(1.65,0,3.7),.14,6.8,'brown',rot=(0,0,0),verts=8); sphere('RightHand_StaffLumen',(1.65,0,7.0),(1.0,1.0,1.0),'lumen'); return export('SerenPathkeeper')
if __name__=='__main__':
 mats(); out={}
 for fn in [ilyra,orin,tovin,maela,seren]:
  clear(); r=fn(); out[Path(r['file']).stem]=r
 (OUT/'manifest.json').write_text(json.dumps(out,indent=2)); print(json.dumps(out,indent=2))
