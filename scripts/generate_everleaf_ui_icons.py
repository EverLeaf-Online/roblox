#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/ui/icons'
OUT.mkdir(parents=True, exist_ok=True)
S = 512
FINAL = 128
MINT=(113,238,170,255)
MINT2=(198,255,226,255)
TEAL=(45,129,93,255)
DEEP=(16,40,32,255)
GOLD=(235,190,91,255)
GOLD2=(255,226,142,255)
BROWN=(116,78,50,255)
CREAM=(232,238,219,255)
INK=(14,24,22,255)
PURPLE=(185,144,229,255)
BLUE=(119,184,236,255)


def canvas():
    return Image.new('RGBA',(S,S),(0,0,0,0))

def glow(im, radius=22, alpha=125):
    a=im.getchannel('A').filter(ImageFilter.GaussianBlur(radius))
    glow_im=Image.new('RGBA', im.size, (101,245,175,0))
    glow_im.putalpha(a.point(lambda v: int(v*alpha/255)))
    return Image.alpha_composite(glow_im, im)

def line(draw, pts, fill, width=20, joint='curve'):
    draw.line(pts, fill=fill, width=width, joint=joint)

def polygon(draw, pts, fill, outline=None, width=1):
    draw.polygon(pts, fill=fill)
    if outline:
        draw.line(pts+[pts[0]], fill=outline, width=width, joint='curve')

def leaf(draw, center, scale=1.0, rot=-25, fill=MINT, vein=MINT2):
    cx,cy=center
    pts=[(-8,88),(-52,48),(-66,-12),(-34,-70),(0,-96),(39,-61),(62,-8),(47,50),(8,88)]
    ang=math.radians(rot)
    out=[]
    for x,y in pts:
        x*=scale; y*=scale
        out.append((cx+x*math.cos(ang)-y*math.sin(ang), cy+x*math.sin(ang)+y*math.cos(ang)))
    polygon(draw,out,fill)
    def tr(x,y):
        x*=scale; y*=scale
        return (cx+x*math.cos(ang)-y*math.sin(ang), cy+x*math.sin(ang)+y*math.cos(ang))
    line(draw,[tr(0,72),tr(0,-72)],vein,max(5,int(9*scale)))
    line(draw,[tr(0,10),tr(-34,-25)],vein,max(4,int(6*scale)))
    line(draw,[tr(0,-14),tr(32,-43)],vein,max(4,int(6*scale)))

def ring(draw, center, r, color, width=22):
    cx,cy=center
    draw.ellipse((cx-r,cy-r,cx+r,cy+r),outline=color,width=width)

def save(name, im, add_glow=False):
    if add_glow:
        im=glow(im)
    im.resize((FINAL,FINAL), Image.Resampling.LANCZOS).save(OUT/f'{name}.png')

# Shard: asymmetrical crystal fan with etched leaf rune
im=canvas(); d=ImageDraw.Draw(im)
crystals=[[(165,373),(135,226),(197,96),(245,232),(224,389)],[(229,385),(220,154),(287,58),(329,181),(300,390)],[(298,390),(322,225),(385,128),(403,292),(357,395)]]
cols=[TEAL,MINT,MINT2]
for pts,c in zip(crystals,cols): polygon(d,pts,c,(218,255,235,255),10)
line(d,[(255,328),(278,210)],(235,255,244,240),11)
line(d,[(270,253),(241,222)],(235,255,244,220),8)
line(d,[(269,252),(306,226)],(235,255,244,220),8)
line(d,[(154,401),(366,401)],(61,151,108,220),18)
save('shard',im,True)

# Mark: ancient octagonal token with original leaf-rune cutout
im=canvas(); d=ImageDraw.Draw(im)
pts=[]
for i in range(8):
    a=math.radians(22.5+i*45); pts.append((256+172*math.cos(a),256+172*math.sin(a)))
polygon(d,pts,(151,103,47,255),GOLD2,18)
ring(d,(256,256),118,GOLD,18)
leaf(d,(256,250),0.62,-18,GOLD2,(255,244,189,255))
# rune notches
for a in [0,90,180,270]:
    rad=math.radians(a); x=256+145*math.cos(rad); y=256+145*math.sin(rad)
    d.rounded_rectangle((x-13,y-13,x+13,y+13),radius=6,fill=INK)
save('mark',im,False)

# Character: hooded Wayfarer bust + leaf clasp
im=canvas(); d=ImageDraw.Draw(im)
d.ellipse((170,72,342,244),fill=(66,98,78,255),outline=MINT,width=14)
d.polygon([(158,225),(354,225),(415,422),(97,422)],fill=(37,66,54,255),outline=MINT,width=13)
d.ellipse((204,113,308,229),fill=(210,176,142,255))
d.polygon([(174,115),(256,61),(338,118),(307,153),(256,132),(205,155)],fill=(48,75,62,255))
leaf(d,(257,323),0.42,-15,MINT,MINT2)
line(d,[(134,390),(378,390)],(72,123,97,255),12)
save('character',im,False)

# Inventory: irregular Wayfarer satchel with leaf clasp & straps
im=canvas(); d=ImageDraw.Draw(im)
d.rounded_rectangle((105,172,407,414),radius=48,fill=(103,72,48,255),outline=(193,149,91,255),width=14)
d.rounded_rectangle((128,136,384,236),radius=38,fill=(126,87,56,255),outline=(218,172,105,255),width=12)
line(d,[(155,174),(198,77),(314,77),(359,174)],(87,58,39,255),22)
d.rounded_rectangle((226,225,286,290),radius=15,fill=(62,107,82,255),outline=MINT,width=8)
leaf(d,(256,257),0.23,-18,MINT,MINT2)
line(d,[(147,326),(365,326)],(77,50,34,180),9)
save('inventory',im,False)

# Skills: curved branch-blade slash around lumen rune
im=canvas(); d=ImageDraw.Draw(im)
# slash arc
pts=[]
for i in range(28):
    a=math.radians(-145+i*8); r=170-0.55*i
    pts.append((256+r*math.cos(a),256+r*math.sin(a)))
line(d,pts,(232,246,238,255),24)
line(d,[(128,346),(184,304),(224,258),(260,204)],(105,72,44,255),27)
# twig off branch
line(d,[(183,303),(152,252)],(105,72,44,255),13)
leaf(d,(283,231),0.38,32,MINT,MINT2)
d.ellipse((307,102,361,156),fill=MINT2)
d.ellipse((323,118,345,140),fill=MINT)
save('skills',im,True)

# Quests: curled map with a path ending in leaf waypoint
im=canvas(); d=ImageDraw.Draw(im)
d.rounded_rectangle((104,112,407,399),radius=32,fill=(218,205,163,255),outline=(126,92,55,255),width=14)
d.ellipse((83,107,157,183),fill=(157,119,70,255),outline=(104,71,41,255),width=9)
d.ellipse((354,329,428,405),fill=(157,119,70,255),outline=(104,71,41,255),width=9)
# path
path=[(160,326),(204,294),(188,244),(250,219),(298,253),(344,190)]
line(d,path,(84,99,66,255),16)
for x,y in path[:-1]: d.ellipse((x-9,y-9,x+9,y+9),fill=(62,118,85,255))
leaf(d,(349,177),0.31,-22,MINT,TEAL)
save('quests',im,False)

# Settings: woven branch ring, not a generic gear
im=canvas(); d=ImageDraw.Draw(im)
ring(d,(256,256),132,(111,78,49,255),26)
for a in range(0,360,45):
    rad=math.radians(a); x1=256+112*math.cos(rad); y1=256+112*math.sin(rad); x2=256+169*math.cos(rad); y2=256+169*math.sin(rad)
    line(d,[(x1,y1),(x2,y2)],(111,78,49,255),18)
    lx=256+159*math.cos(rad+0.20); ly=256+159*math.sin(rad+0.20)
    leaf(d,(lx,ly),0.14,a+40,MINT,MINT2)
ring(d,(256,256),54,MINT,15)
# asymmetric tuning slash
line(d,[(214,286),(300,205)],MINT2,15)
save('settings',im,False)

# Objective: Wayfinder compass rose fused with a leaf
im=canvas(); d=ImageDraw.Draw(im)
ring(d,(256,256),146,(72,117,95,255),14)
polygon(d,[(256,80),(286,236),(256,278),(226,236)],MINT2,MINT,8)
polygon(d,[(256,432),(286,276),(256,236),(226,276)],(52,113,83,255),MINT,8)
leaf(d,(326,286),0.28,42,MINT,MINT2)
d.ellipse((236,236,276,276),fill=GOLD,outline=GOLD2,width=7)
save('objective',im,False)

# Beginner Strike: broad crescent slash + branch sword
im=canvas(); d=ImageDraw.Draw(im)
# crescent using thick arc
bbox=(70,70,442,442)
d.arc(bbox,start=205,end=345,fill=(230,248,239,255),width=44)
d.arc((96,96,416,416),start=205,end=345,fill=MINT,width=11)
line(d,[(166,355),(345,159)],(114,78,45,255),28)
polygon(d,[(337,154),(392,110),(362,184)],MINT2,MINT,8)
leaf(d,(210,303),0.22,32,MINT,MINT2)
save('beginner_strike',im,True)

# Steady Footing: rooted boot/step emblem
im=canvas(); d=ImageDraw.Draw(im)
d.polygon([(160,120),(281,120),(296,278),(370,314),(359,391),(144,391),(120,337),(162,280)],fill=(74,103,85,255),outline=MINT,width=14)
# sole
d.rounded_rectangle((132,354,374,410),radius=20,fill=(95,64,42,255),outline=(166,120,72,255),width=10)
# roots
for end in [(82,442),(174,448),(257,454),(346,444),(430,426)]:
    line(d,[(255,389),end],(115,80,48,255),13)
leaf(d,(250,230),0.30,-12,MINT,MINT2)
save('steady_footing',im,False)


# Frame border: original EverLeaf vine/rune 9-slice frame overlay
im=canvas(); d=ImageDraw.Draw(im)
# angular outer frame
frame=[(54,22),(458,22),(490,54),(490,458),(458,490),(54,490),(22,458),(22,54)]
d.line(frame+[frame[0]],fill=(80,160,121,235),width=14,joint='curve')
inner=[(68,43),(444,43),(469,68),(469,444),(444,469),(68,469),(43,444),(43,68)]
d.line(inner+[inner[0]],fill=(31,83,61,170),width=7,joint='curve')
# corner branch flourishes
for sx,sy,rot in [(1,1,-35),(-1,1,35),(1,-1,215),(-1,-1,145)]:
    cx=76 if sx==1 else 436; cy=76 if sy==1 else 436
    ex=cx+(78*sx); ey=cy+(34*sy)
    line(d,[(cx,cy),(ex,ey)],(96,70,43,235),12)
    leaf(d,(cx+42*sx,cy+18*sy),0.17,rot,MINT,MINT2)
    leaf(d,(cx+68*sx,cy+28*sy),0.12,rot+55,(77,183,132,255),MINT2)
# lumen rune ticks along top/bottom
for x in (184,256,328):
    polygon(d,[(x,28),(x+8,36),(x,44),(x-8,36)],MINT2,MINT,3)
    polygon(d,[(x,484),(x+8,476),(x,468),(x-8,476)],MINT2,MINT,3)
# transparent interior by design
im.resize((256,256), Image.Resampling.LANCZOS).save(OUT/'frame_border.png')
print('generated frame_border')

print('generated', len(list(OUT.glob('*.png'))), 'icons in', OUT)
