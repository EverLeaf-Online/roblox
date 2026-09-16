#!/usr/bin/env python3
# Original EverLeaf Lumenreach elite/boss monster batch.
# Run: blender --background --python scripts/generate_lumenreach_elite_monsters.py
import bpy, math, json, struct, zlib, binascii
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'original'/'lumenreach_elite_monsters'
OUT.mkdir(parents=True,exist_ok=True)
PALETTE={
 'bone':(0.68,0.72,0.63,1),'bone_dark':(0.38,0.42,0.36,1),'grave':(0.20,0.28,0.28,1),
 'iron':(0.24,0.27,0.27,1),'bronze':(0.55,0.35,0.15,1),'cloth':(0.25,0.18,0.26,1),
 'lumen':(0.24,0.95,0.70,1),'cap':(0.48,0.16,0.34,1),'cap_light':(0.86,0.55,0.64,1),
 'gel':(0.25,0.58,0.38,1),'root':(0.24,0.16,0.10,1),'bark':(0.31,0.23,0.14,1),
 'moss':(0.26,0.47,0.24,1),'leaf':(0.46,0.68,0.28,1),'stone':(0.36,0.40,0.36,1),
 'eye':(0.90,1.0,0.72,1),'red':(0.68,0.12,0.12,1)
}
KEYS=list(PALETTE); GRID=5; CELL=12; ATLAS=OUT/'elite_monster_palette.png'
M=None

def write_png():
    w=h=GRID*CELL; rows=[]
    for y in range(h):
        row=bytearray([0]); cy=y//CELL
        for x in range(w):
            idx=cy*GRID+x//CELL
            rgb=PALETTE[KEYS[idx]][:3] if idx<len(KEYS) else (1,0,1)
            row.extend(max(0,min(255,round(c*255))) for c in rgb)
        rows.append(bytes(row))
    def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',binascii.crc32(t+d)&0xffffffff)
    ATLAS.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows),9))+chunk(b'IEND',b''))

def material():
    write_png(); img=bpy.data.images.load(str(ATLAS),check_existing=True)
    m=bpy.data.materials.get('EL_EliteMonsterPalette') or bpy.data.materials.new('EL_EliteMonsterPalette'); m.use_nodes=True
    nodes=m.node_tree.nodes; links=m.node_tree.links; b=nodes.get('Principled BSDF')
    t=nodes.get('EL_Palette') or nodes.new('ShaderNodeTexImage'); t.name='EL_Palette'; t.image=img; t.interpolation='Closest'
    links.new(t.outputs['Color'],b.inputs['Base Color']); b.inputs['Roughness'].default_value=.68
    return m

def clear(): bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def uv(o,key):
    idx=KEYS.index(key); u=(idx%GRID+.5)/GRID; v=1-(idx//GRID+.5)/GRID
    layer=o.data.uv_layers.get('UVMap') or o.data.uv_layers.new(name='UVMap')
    for poly in o.data.polygons:
        for li in poly.loop_indices: layer.data[li].uv=(u,v)
    o.data.materials.clear(); o.data.materials.append(M)

def cube(name,loc,dims,key,rot=(0,0,0),bevel=.08):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot); o=bpy.context.object; o.name=name; o.dimensions=dims
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('edge','BEVEL'); mod.width=bevel; mod.segments=1; bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    uv(o,key); return o

def sphere(name,loc,scale,key,segments=12,rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=loc); o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); uv(o,key); return o

def cyl(name,loc,radius,depth,key,rot=(0,0,0),verts=10):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=radius,depth=depth,location=loc,rotation=rot); o=bpy.context.object; o.name=name; uv(o,key); return o

def cone(name,loc,r1,r2,depth,key,rot=(0,0,0),verts=7):
    bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r1,radius2=r2,depth=depth,location=loc,rotation=rot); o=bpy.context.object; o.name=name; uv(o,key); return o

def export(name):
    path=OUT/(name+'.glb'); bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_materials='EXPORT')
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    return {'file':str(path.relative_to(ROOT)),'triangles':sum(sum(max(0,len(p.vertices)-2) for p in o.data.polygons) for o in meshes),'vertices':sum(len(o.data.vertices) for o in meshes),'parts':[o.name for o in meshes]}

def skeleton_body(captain=False):
    # Deliberately lanky asymmetrical gravebone silhouette; each major limb remains a separately animated part.
    sphere('Body',(0,3.0,0),(1.05,1.35,.68),'grave',10,6)
    sphere('Head',(0,4.75,-.12),(.82,.86,.75),'bone',10,6)
    for x in (-.28,.28): sphere('EyeL' if x<0 else 'EyeR',(x,4.86,-.79),(.13,.12,.08),'lumen',8,5)
    cube('Jaw',(0,4.25,-.47),(1.0,.32,.52),'bone_dark',bevel=.1)
    cube('LeftArm',(-1.25,3.05,0),(.45,2.5,.45),'bone',rot=(0,0,math.radians(-8)),bevel=.1)
    cube('RightArm',(1.28,3.0,-.05),(.48,2.7,.48),'bone',rot=(0,0,math.radians(10)),bevel=.1)
    cube('LeftLeg',(-.55,1.25,.1),(.52,2.7,.55),'bone',rot=(0,0,math.radians(2)),bevel=.1)
    cube('RightLeg',(.55,1.25,.05),(.52,2.7,.55),'bone',rot=(0,0,math.radians(-2)),bevel=.1)
    # Rib cage slats remain static root attachments and make the silhouette clearly skeletal rather than mannequin-like.
    for i,y in enumerate((2.55,2.95,3.35,3.75)):
        cube('Rib'+str(i+1),(0,y,-.05),(2.15,.22,.72),'bone_dark',bevel=.07)
    cube('Spine',(0,3.05,.33),(.28,2.5,.28),'bone_dark',bevel=.05)
    if captain:
        cube('CaptainCuirass',(0,3.18,-.1),(2.55,2.25,1.18),'iron',bevel=.16)
        cone('HelmCrest',(0,5.78,.05),.42,.05,1.55,'red',rot=(0,0,0),verts=6)
        cube('HelmBrow',(0,4.95,-.45),(1.75,.42,.95),'iron',bevel=.1)
        cyl('Shield',(-1.55,3.0,-.35),1.15,.30,'bronze',rot=(math.radians(90),0,0),verts=10)
        cube('CaptainBlade',(1.72,2.65,-.15),(.22,3.25,.52),'iron',rot=(0,0,math.radians(-15)),bevel=.05)
        cube('BladeEdge',(1.60,1.25,-.15),(.52,1.15,.18),'bone_dark',rot=(0,0,math.radians(-15)),bevel=.04)
    else:
        cube('Graveblade',(1.56,2.45,-.15),(.20,2.8,.42),'iron',rot=(0,0,math.radians(-11)),bevel=.04)

def skeleton():
    clear(); skeleton_body(False); return export('GraveboneSkeleton')

def captain():
    clear(); skeleton_body(True); return export('GraveboneCaptain')

def royal_glowcap():
    clear()
    sphere('Body',(0,1.45,0),(2.25,1.35,2.1),'gel',14,9)
    sphere('Face',(0,1.72,-1.50),(1.35,.72,.62),'grave',12,7)
    for x in (-.5,.5): sphere('EyeL' if x<0 else 'EyeR',(x,1.88,-2.05),(.18,.20,.12),'eye',8,5)
    # Multi-tier crown cap with asymmetrical satellite caps, distinct from ordinary glowcap slime.
    sphere('CrownCap',(0,3.15,0),(3.25,.78,2.85),'cap',16,9)
    cone('CrownStem',(0,4.08,.05),1.2,.38,2.1,'cap_light',verts=8)
    for i,(x,z,s) in enumerate([(-2.3,.2,.85),(2.1,.65,.7),(-1.1,1.8,.62),(1.35,-1.75,.58)]):
        sphere('RoyalNode'+str(i+1),(x,3.0,z),(s,.32,s*.9),'cap_light',10,6)
    for i,(x,z) in enumerate([(-1.6,-1.4),(-.6,-2.15),(.65,-2.08),(1.7,-1.25),(0,.85)]):
        sphere('CrownSpot'+str(i+1),(x,3.56,z),(.30,.12,.30),'lumen',8,5)
    return export('RoyalGlowcap')

def mosswarden():
    clear()
    # Ancient grove guardian: heavy root-beast body, stone heart, antler canopy, four animated root legs.
    sphere('Body',(0,4.15,.35),(3.55,2.45,4.25),'bark',14,9)
    sphere('Head',(0,4.35,-3.75),(2.05,1.65,1.75),'root',12,8)
    sphere('Heart',(0,4.45,-1.05),(.78,1.0,.50),'lumen',10,6)
    for x in (-.7,.7): sphere('EyeL' if x<0 else 'EyeR',(x,4.72,-5.14),(.24,.22,.16),'eye',8,5)
    for name,x,z in [('FrontLeftLeg',-2.25,-2.15),('FrontRightLeg',2.25,-2.15),('BackLeftLeg',-2.35,2.25),('BackRightLeg',2.35,2.25)]:
        cube(name,(x,1.65,z),(1.05,3.6,1.15),'root',rot=(0,0,math.radians(-5 if x<0 else 5)),bevel=.2)
        cone(name+'Claw',(x,.15,z-.35),.68,.15,1.5,'stone',rot=(math.radians(90),0,0),verts=7)
    # Antler/root canopy, intentionally wide hero silhouette.
    for side in (-1,1):
        cube('AntlerBaseL' if side<0 else 'AntlerBaseR',(side*1.15,6.0,-3.55),(.55,3.2,.55),'root',rot=(0,0,math.radians(-28*side)),bevel=.12)
        cube('AntlerBranchL' if side<0 else 'AntlerBranchR',(side*2.15,7.05,-3.35),(2.25,.45,.48),'root',rot=(0,0,math.radians(18*side)),bevel=.1)
        cone('AntlerTipL' if side<0 else 'AntlerTipR',(side*3.1,7.6,-3.3),.42,.06,1.7,'leaf',rot=(0,0,math.radians(-24*side)),verts=6)
    for i,(x,z,h) in enumerate([(-2.5,.5,1.7),(-1.0,2.7,2.2),(.6,2.9,1.5),(2.45,.3,2.0),(0,.25,2.65)]):
        cone('BackSpire'+str(i+1),(x,6.35,z),.55,.08,h,'moss',verts=7)
    sphere('CanopyMoss',(0,6.2,.8),(2.7,.55,2.9),'moss',12,7)
    return export('Mosswarden')

M=material(); manifest={}
for fn in (skeleton,captain,royal_glowcap,mosswarden):
    data=fn(); manifest[Path(data['file']).stem]=data
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2))
