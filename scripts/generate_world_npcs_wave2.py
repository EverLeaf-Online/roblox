#!/usr/bin/env python3
# Second production NPC batch. Reuses the proven authored R15-aligned visual shell
# helpers but gives every named NPC a role-specific silhouette and prop language.
import json, math, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
import generate_lumenreach_hero_npcs as G

OUT=ROOT/'assets'/'original'/'world_npcs_wave2'; OUT.mkdir(parents=True,exist_ok=True)
G.OUT=OUT; G.ATLAS=OUT/'npc_wave2_palette.png'
G.PAL.update({
 'iron':(0.24,0.27,0.27,1),
 'red':(0.48,0.15,0.13,1),
 'teal':(0.12,0.38,0.38,1),
 'white':(0.76,0.75,0.66,1),
})
G.KEYS=list(G.PAL); G.GRID=4; G.CELL=16; G.M.clear(); G.mats()

def eira():
    G.base_body('cream','green2','skin',.92); G.hair('bun','brown')
    G.box('UpperTorso_HealerMantle',(0,.22,5.68),(3.0,1.45,.75),'green2',.14)
    G.box('UpperTorso_Apron',(0,-.69,4.55),(2.25,.28,3.0),'cream',.05)
    G.box('LowerTorso_HerbSatchel',(1.05,-.55,3.65),(1.05,.55,1.35),'leather',.08)
    for i,x in enumerate((-1.42,-.95,-.48)):
        G.cyl('LowerTorso_Vial'+str(i+1),(x,-.67,3.65),.12,.8,'lumen',rot=(0,0,0),verts=8)
    G.box('LeftHand_HerbBook',(-1.66,-.45,2.55),(1.25,.38,1.6),'green',.06,rot=(math.radians(15),0,math.radians(-7)))
    return G.export('EiraWayfarerHealer')

def sella():
    G.base_body('teal','green','skin2',.96); G.hair('hood','teal')
    G.box('UpperTorso_WetlandCape',(0,.55,4.9),(2.65,.38,3.3),'green',.08)
    G.cyl('RightHand_ReedStaff',(1.65,0,3.6),.13,6.6,'brown',verts=8)
    for i,(x,z) in enumerate([(1.38,6.5),(1.75,6.75),(2.05,6.45)]):
        G.cyl('RightHand_Reed'+str(i+1),(x,0,z),.09,1.8,'green2',verts=7)
    G.box('LowerTorso_ReedBundle',(-1.05,.55,3.7),(1.1,.55,2.6),'green2',.08,rot=(0,math.radians(8),math.radians(-8)))
    return G.export('SellaGlowmereKeeper')

def aven():
    G.base_body('blue','violet','skin',.90); G.hair('short','brown')
    G.box('UpperTorso_FieldPack',(0,.78,4.85),(2.1,.75,2.65),'brown',.12)
    G.box('UpperTorso_InstrumentCase',(1.18,.62,4.8),(.75,.65,2.8),'gold',.08)
    G.box('LeftHand_Notebook',(-1.65,-.42,2.6),(1.15,.35,1.5),'cream',.05,rot=(math.radians(16),0,math.radians(-5)))
    G.cyl('RightHand_SurveyLens',(1.66,-.2,2.75),.48,.18,'gold',rot=(math.radians(90),0,0),verts=12)
    G.box('Head_Goggles',(-.47,-.93,7.34),(.72,.15,.42),'gold',.03); G.box('Head_Goggles2',(.47,-.93,7.34),(.72,.15,.42),'gold',.03)
    return G.export('AvenSunmossResearcher')

def neris():
    G.base_body('dark','blue','skin2',1.0); G.hair('long','dark')
    G.box('UpperTorso_WardenMantle',(0,.12,5.78),(3.25,1.55,.82),'blue',.14)
    G.box('UpperTorso_LongCape',(0,.58,4.25),(2.7,.4,4.2),'dark',.08)
    G.box('Head_VeilMask',(0,-.94,7.05),(1.45,.18,.7),'teal',.05)
    G.cyl('RightHand_CrystalLantern',(1.65,-.1,2.9),.48,.85,'gold',verts=8)
    G.sphere('RightHand_VeilCrystal',(1.65,-.1,2.9),(.7,.7,.7),'lumen')
    return G.export('NerisVeilfallWarden')

def nera():
    G.base_body('brown','iron','skin2',1.08); G.hair('short','dark')
    G.box('UpperTorso_ForgeApron',(0,-.72,4.55),(2.5,.3,3.2),'iron',.06)
    G.box('UpperTorso_ShoulderPad',(-1.22,-.05,5.75),(1.25,1.45,.65),'gold',.12)
    G.box('LowerTorso_KeyRing',(1.1,-.65,3.75),(.8,.28,1.0),'gold',.05)
    G.box('LeftHand_StockLedger',(-1.65,-.45,2.55),(1.35,.4,1.75),'cream',.05,rot=(math.radians(15),0,math.radians(-8)))
    return G.export('NeraFoundryQuartermaster')

def cale():
    G.base_body('violet','gold','skin',.94); G.hair('short','brown')
    G.box('UpperTorso_BrokerCoat',(0,.12,4.65),(2.6,1.4,3.4),'violet',.10)
    G.box('UpperTorso_MarkCase',(.95,.72,4.65),(1.1,.55,2.0),'gold',.08)
    G.box('LeftHand_Ledger',(-1.65,-.4,2.6),(1.25,.35,1.65),'cream',.05,rot=(math.radians(12),0,math.radians(-6)))
    G.cyl('Head_Monocle',(.45,-.94,7.2),.28,.08,'gold',rot=(math.radians(90),0,0),verts=12)
    return G.export('CaleMarkBroker')

def tamsin():
    G.base_body('teal','iron','skin',.96); G.hair('short','brown')
    G.box('Head_EngineerCap',(0,.02,7.82),(2.25,1.85,.55),'iron',.12)
    G.box('Head_Goggles',(-.48,-.95,7.33),(.75,.16,.4),'lumen',.03); G.box('Head_Goggles2',(.48,-.95,7.33),(.75,.16,.4),'lumen',.03)
    G.box('UpperTorso_ToolHarness',(0,-.68,4.85),(2.35,.32,2.5),'brown',.06)
    G.box('LowerTorso_ToolPouch',(1.08,-.62,3.55),(.9,.55,1.2),'leather',.08)
    G.box('RightHand_Wrench',(1.65,0,2.85),(.32,.35,2.8),'iron',.06,rot=(0,0,math.radians(-8)))
    G.box('RightHand_WrenchJaw',(1.65,0,1.55),(.9,.35,.55),'iron',.05)
    return G.export('TamsinEastworksEngineer')

def mara():
    G.base_body('dark','red','skin2',1.02); G.hair('long','dark')
    G.box('UpperTorso_OathMantle',(0,.05,5.8),(3.35,1.7,.85),'red',.14)
    G.box('UpperTorso_ForgePlate',(0,-.62,4.85),(2.45,.42,2.6),'iron',.08)
    for side in (-1,1):
        G.box('UpperTorso_PauldronL' if side<0 else 'UpperTorso_PauldronR',(side*1.35,0,5.75),(1.25,1.55,.75),'gold',.12,rot=(0,0,math.radians(8*side)))
    G.cyl('RightHand_OathHammer',(1.65,0,3.45),.16,4.8,'brown',verts=8)
    G.box('RightHand_HammerHead',(1.65,0,5.7),(2.2,.8,.9),'iron',.12)
    G.sphere('RightHand_Ember',(1.65,-.45,5.7),(.65,.5,.65),'lumen')
    return G.export('MaraForgeOathkeeper')

def rook():
    G.base_body('dark','red','skin',1.08); G.hair('short','dark')
    G.box('UpperTorso_CommandCoat',(0,.2,4.6),(2.75,1.45,3.5),'dark',.10)
    G.box('UpperTorso_CommandPauldron',(-1.35,-.05,5.8),(1.45,1.55,.75),'red',.12,rot=(0,0,math.radians(-10)))
    G.box('UpperTorso_Badge',(.65,-.78,5.35),(.55,.15,.75),'gold',.04)
    G.box('RightHand_MarshalSaber',(1.7,0,2.8),(.18,.36,3.2),'iron',.04,rot=(0,0,math.radians(-10)))
    G.box('RightHand_SaberGuard',(1.7,0,4.1),(1.0,.35,.18),'gold',.04)
    return G.export('RookBelforgeMarshal')

def vale():
    G.base_body('brown','iron','skin2',1.13); G.hair('short','dark')
    G.box('Head_ForemanCap',(0,.02,7.82),(2.35,1.9,.58),'gold',.12)
    G.box('UpperTorso_WorkHarness',(0,-.7,4.8),(2.55,.35,2.8),'leather',.06)
    G.box('UpperTorso_ShoulderGuard',(1.25,-.02,5.75),(1.35,1.5,.7),'iron',.12)
    G.box('LowerTorso_BlueprintTube',(-1.12,.55,3.65),(.7,.7,2.4),'blue',.08)
    G.cyl('RightHand_ForemanHammer',(1.65,0,3.2),.16,4.1,'brown',verts=8)
    G.box('RightHand_HammerHead',(1.65,0,5.0),(1.9,.8,.85),'iron',.1)
    return G.export('ValeBelforgeForeman')

if __name__=='__main__':
    out={}
    for fn in [eira,sella,aven,neris,nera,cale,tamsin,mara,rook,vale]:
        G.clear(); r=fn(); out[Path(r['file']).stem]=r
    (OUT/'manifest.json').write_text(json.dumps(out,indent=2)); print(json.dumps(out,indent=2))
