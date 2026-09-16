#!/usr/bin/env python3
# Run with: blender --background --python scripts/generate_starter_monsters.py
import bpy, math, json, struct, zlib, binascii
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'original'/'starter_monsters'
OUT.mkdir(parents=True,exist_ok=True)

PALETTE={
 'moss_dark':(0.15,0.28,0.16,1),'moss':(0.28,0.48,0.24,1),'leaf':(0.48,0.69,0.28,1),
 'lumen':(0.24,0.95,0.70,1),'slime':(0.28,0.63,0.42,1),'cap':(0.56,0.24,0.38,1),
 'cap_spot':(0.90,0.72,0.54,1),'bird':(0.66,0.48,0.20,1),'bird_dark':(0.20,0.24,0.22,1),
 'beak':(0.89,0.58,0.20,1),'bramble':(0.30,0.22,0.15,1),'bark':(0.20,0.14,0.10,1),
 'thorn':(0.42,0.58,0.25,1),'bone':(0.72,0.76,0.67,1),'wisp':(0.18,0.74,0.72,1),
 'wisp_dark':(0.08,0.28,0.31,1),'eye':(0.88,1.0,0.75,1)
}
KEYS=list(PALETTE); GRID=5; CELL=12; ATLAS=OUT/'starter_monster_palette.png'

def png():
 w=h=GRID*CELL; rows=[]
 for y in range(h):
  row=bytearray([0]); cy=y//CELL
  for x in range(w):
   idx=cy*GRID+x//CELL
   rgb=PALETTE[KEYS[idx]][:3] if idx<len(KEYS) else (1,0,1)
   row.extend(max(0,min(255,round(c*255))) for c in rgb)
  rows.append(bytes(row))
 def ch(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',binascii.crc32(t+d)&0xffffffff)
 data=b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+ch(b'IDAT',zlib.compress(b''.join(rows),9))+ch(b'IEND',b'')
 ATLAS.write_bytes(data)

def mat():
 png(); m=bpy.data.materials.new('EL_StarterMonsterPalette'); m.use_nodes=True
 img=bpy.data.images.load(str(ATLAS)); n=m.node_tree.nodes.new('ShaderNodeTexImage'); n.image=img; n.interpolation='Closest'
 b=m.node_tree.nodes.get('Principled BSDF'); m.node_tree.links.new(n.outputs['Color'],b.inputs['Base Color']); b.inputs['Roughness'].default_value=.7
 return m
M=None

def clear():
 bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def uv(obj,key):
 idx=KEYS.index(key); col=idx%GRID; row=idx//GRID; u=(col+.5)/GRID; v=1-(row+.5)/GRID
 layer=obj.data.uv_layers.get('UVMap') or obj.data.uv_layers.new(name='UVMap')
 for poly in obj.data.polygons:
  for li in poly.loop_indices: layer.data[li].uv=(u,v)
 obj.data.materials.clear(); obj.data.materials.append(M)

def sphere(name,loc,scale,key,segments=12,rings=8):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
 o=bpy.context.object; o.name=name; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); uv(o,key); return o

def cube(name,loc,scale,key,rot=(0,0,0),bevel=.08):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot); o=bpy.context.object;o.name=name;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  m=o.modifiers.new('edge','BEVEL');m.width=bevel;m.segments=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
 uv(o,key); return o

def cone(name,loc,r1,r2,depth,key,rot=(0,0,0),verts=8):
 bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=depth,location=loc,rotation=rot);o=bpy.context.object;o.name=name;uv(o,key);return o

def export(name):
 path=OUT/(name+'.glb'); bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_materials='EXPORT')
 tris=sum(sum(max(0,len(p.vertices)-2) for p in o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH')
 verts=sum(len(o.data.vertices) for o in bpy.context.scene.objects if o.type=='MESH')
 return {'file':str(path.relative_to(ROOT)),'triangles':tris,'vertices':verts,'parts':[o.name for o in bpy.context.scene.objects if o.type=='MESH']}

def mossling():
 clear(); sphere('Body',(0,1.45,0),(1.75,1.25,1.55),'moss',12,8)
 sphere('Head',(0,2.55,-.45),(1.18,.78,1.05),'moss_dark',12,8)
 for x in (-.43,.43): sphere('EyeL' if x<0 else 'EyeR',(x,2.72,-1.32),(.18,.18,.12),'eye',8,5)
 for x,z,r in [(-.9,.1,-.45),(0,.25,0),(.9,.1,.45)]: cone('Leaf', (x,3.35,z), .42,.04,1.7,'leaf',rot=(0,r,math.radians(-10 if x<0 else 10)),verts=6)
 for x in (-1.15,1.15): cube('FootL' if x<0 else 'FootR',(x,.45,.2),(.85,.45,1.15),'moss_dark',rot=(0,math.radians(8*x),0),bevel=.18)
 return export('LumenMossling')

def glowcap():
 clear(); sphere('Body',(0,1.15,0),(1.65,1.15,1.55),'slime',14,9)
 sphere('Face',(0,1.5,-1.05),(1.0,.65,.55),'moss_dark',12,7)
 for x in (-.38,.38): sphere('EyeL' if x<0 else 'EyeR',(x,1.65,-1.58),(.14,.18,.10),'eye',8,5)
 # broad mushroom cap distinct silhouette
 sphere('Cap',(0,2.55,0),(2.35,.65,2.05),'cap',14,8)
 for x,z in [(-1.1,-.4),(.85,-.65),(-.55,.65),(1.15,.45),(0,.1)]: sphere('Spot',(x,2.92,z),(.25,.10,.25),'cap_spot',8,5)
 return export('GlowcapSlime')

def ridgebeak():
 clear(); sphere('Body',(0,2.35,0),(1.45,1.65,1.2),'bird',12,8)
 sphere('Head',(0,3.6,-.55),(.95,.95,.9),'bird_dark',12,8)
 cone('Beak',(0,3.45,-1.72),.48,.02,1.25,'beak',rot=(math.radians(90),0,0),verts=6)
 for x in (-.34,.34): sphere('EyeL' if x<0 else 'EyeR',(x,3.88,-1.29),(.12,.12,.09),'eye',8,5)
 cube('LeftWing',(-1.55,2.5,.05),(1.6,.38,2.15),'bird_dark',rot=(0,0,math.radians(-18)),bevel=.16)
 cube('RightWing',(1.55,2.5,.05),(1.6,.38,2.15),'bird_dark',rot=(0,0,math.radians(18)),bevel=.16)
 cube('LeftLeg',(-.55,.9,.2),(.32,1.9,.32),'beak',bevel=.06); cube('RightLeg',(.55,.9,.2),(.32,1.9,.32),'beak',bevel=.06)
 for x in (-.55,.55):
  cube('LeftFoot' if x<0 else 'RightFoot',(x,.08,-.25),(.85,.22,1.05),'beak',rot=(math.radians(4),0,0),bevel=.05)
 cone('Tail',(0,2.5,1.65),.8,.18,2.2,'bird_dark',rot=(math.radians(90),0,0),verts=6)
 return export('SuncrestRidgebeak')

def brambleback():
 clear(); sphere('Body',(0,2.15,0),(2.25,1.45,2.75),'bramble',12,8)
 sphere('Head',(0,2.15,-2.55),(1.35,1.05,1.25),'bark',12,8)
 cone('Snout',(0,1.95,-3.65),.72,.42,1.2,'bark',rot=(math.radians(90),0,0),verts=8)
 # thorn carapace line
 for i,x in enumerate((-1.45,-.7,0,.7,1.45)):
  cone('Thorn', (x,3.65,.25+abs(x)*.3), .48,.02,1.7,'thorn',rot=(math.radians(-8),0,0),verts=6)
 for name,x,z in [('FrontLeftLeg',-1.45,-1.45),('FrontRightLeg',1.45,-1.45),('BackLeftLeg',-1.45,1.45),('BackRightLeg',1.45,1.45)]:
  cube(name,(x,.85,z),(.72,1.7,.82),'bark',bevel=.18)
 for x in (-.65,.65): cone('Tusk', (x,1.92,-3.55), .22,.02,.85,'bone',rot=(math.radians(65),0,math.radians(12 if x<0 else -12)),verts=6)
 return export('Brambleback')

def wisp():
 clear(); sphere('Body',(0,2.8,0),(1.0,1.35,1.0),'wisp',12,8)
 sphere('Core',(0,2.8,-.62),(.42,.55,.32),'eye',10,6)
 # three orbiting crescent-like fins / shards
 for i,(x,y,z,r) in enumerate([(-1.25,3.15,.2,-28),(1.18,2.55,.35,32),(0,4.15,.1,0)]):
  cube('Shard'+str(i+1),(x,y,z),(.42,1.25,.35),'wisp_dark',rot=(0,0,math.radians(r)),bevel=.14)
 cone('Tail',(0,1.15,.2),.65,.05,2.7,'wisp',rot=(0,0,0),verts=7)
 return export('LumenWisp')

M=mat()
manifest={}
for fn in (mossling,glowcap,ridgebeak,brambleback,wisp):
 data=fn(); manifest[Path(data['file']).stem]=data
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2))
