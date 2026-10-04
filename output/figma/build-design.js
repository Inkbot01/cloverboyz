
const page = await figma.getNodeByIdAsync("0:1");
await figma.setCurrentPageAsync(page);
await Promise.all([{family:"Source Sans Pro",style:"Regular"},{family:"Source Sans Pro",style:"SemiBold"},{family:"Source Sans Pro",style:"Bold"},{family:"Press Start 2P",style:"Regular"}].map(f=>figma.loadFontAsync(f)));
page.name = "HUD & Character";
const ids = [], variableIds=[];
const colors={Ink:"#11181B",Panel:"#182124",Raised:"#222C2E",Track:"#090F12",Line:"#364142",Gold:"#BAA06C",GoldLight:"#E4CE9F",GoldDim:"#675E4A",Text:"#F0EADB",Muted:"#B1BCB6",Faint:"#899892",Green:"#9BCBA6",GreenDark:"#22382F",Health:"#D05C65",Mana:"#62AAD8",Stamina:"#99BD73",Violet:"#B29DD5",Canvas:"#526968"};
const rgb=h=>({r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255});
const coll=figma.variables.createVariableCollection("Cloverboyz / Theme");
coll.renameMode(coll.defaultModeId,"Default");
const vars={};
for(const [k,h] of Object.entries(colors)){
 const v=figma.variables.createVariable(k,coll,"COLOR");v.scopes=["FRAME_FILL","SHAPE_FILL","TEXT_FILL","STROKE_COLOR"];v.setValueForMode(coll.defaultModeId,rgb(h));vars[k]=v;variableIds.push(v.id);
}
const space=figma.variables.createVariableCollection("Cloverboyz / Spacing");
space.renameMode(space.defaultModeId,"Default");
const spaces={};
for(const s of [4,6,8,12,16,24,32]){const v=figma.variables.createVariable(String(s),space,"FLOAT");v.scopes=["GAP"];v.setValueForMode(space.defaultModeId,s);spaces[s]=v;variableIds.push(v.id);}
function paint(c,opacity=1){let p={type:"SOLID",color:rgb(colors[c]||c),opacity};return vars[c]?figma.variables.setBoundVariableForPaint(p,"color",vars[c]):p;}
function track(n){ids.push(n.id);return n;}
function box(parent,name,w,h,color=null,x=0,y=0,component=false){const n=track(component?figma.createComponent():figma.createFrame());n.name=name;n.resize(w,h);n.fills=color?[paint(color)]:[];n.clipsContent=false;parent.appendChild(n);n.x=x;n.y=y;return n;}
function rect(parent,name,w,h,color,x=0,y=0,opacity=1){const n=track(figma.createRectangle());n.name=name;n.resize(w,h);n.fills=[paint(color,opacity)];parent.appendChild(n);n.x=x;n.y=y;return n;}
function label(parent,text,w,h,size=16,color="Text",style="Regular",x=0,y=0,align="LEFT",pixel=false){const n=track(figma.createText());n.name=text;n.fontName={family:pixel?"Press Start 2P":"Source Sans Pro",style:pixel?"Regular":style};n.fontSize=size;n.lineHeight={unit:"PIXELS",value:Math.round(size*(pixel?1.45:1.22))};n.fills=[paint(color)];n.textAutoResize="NONE";n.resize(w,h);n.characters=text;n.textAlignHorizontal=align;n.textAlignVertical="CENTER";parent.appendChild(n);n.x=x;n.y=y;return n;}
function stroke(n,c="Line"){n.strokes=[paint(c)];n.strokeWeight=1;n.strokeAlign="INSIDE";}
function row(parent,name,w,h,gap=8,mode="HORIZONTAL"){const n=box(parent,name,w,h);n.layoutMode=mode;n.itemSpacing=gap;n.counterAxisAlignItems="CENTER";n.primaryAxisSizingMode="FIXED";n.counterAxisSizingMode="FIXED";if(spaces[gap])n.setBoundVariable("itemSpacing",spaces[gap]);return n;}
function instance(component,parent,x=0,y=0){const n=track(component.createInstance());parent.appendChild(n);n.x=x;n.y=y;return n;}
const glyphs={"Icons":["....22....22....","...2332..2332...","..233332233332..",".23333322333332.","2333323223233332","2333233223323332","2222333223332222","...2333223332...","...2333223332...","...2333223332...","...2333223332...","..233332233332..","..233332233332..","..233332233332..","..222222222222..","................"],"Ore":["................","......2222......","....22333322....","...2333333332...","..233332233332..",".23333222333332.",".23332222233332.","2333222222233332","2332222222223332","2322222222222332","2222222222222232",".22222222222222.","..222222222222..","...2222222222...",".....222222.....","................"],"Clover":["................",".2222......2222.","223322....223322","233332....233332","233332....233332",".233322..223332.","..223322223322..","....22222222....","....22222222....","..223322223322..",".233322..223332.","233332....233332","233332....233332","223322....223322",".2222...2..2222.",".......22......."],"Heart":["................","................","..2222....2222..",".223322..223322.","2233332222333322","2333322222233332","2333222222222332","2332222222222222","2222222222222222",".22222222222222.","..222222222222..","...2222222222...","....22222222....",".....222222.....","......2222......",".......22......."],"Sword":["............2222","...........23332","..........23332.",".........23332..","........23332...",".......23332....","......23332.....",".....23332......","..22.23332......","..2223332.......","...22232........","....22222.......","...242.222......","..242...22......",".242............","222............."],"Magic":[".......22.......",".......23.......","......2332......","......2332......",".....223322.....","....22333322....","..222333333222..","2223333333333222","2223333333333222","..222333333222..","....22333322....",".....223322.....","......2332......","......2332......",".......23.......",".......22......."],"Shield":["......2222......","...2223333222...",".22233333333222.",".23322222222332.",".2322......2232.",".232..2332..232.",".232..2332..232.",".232..2332..232.",".232..2332..232.",".232..2332..232.","..232.2332.232..","..232..22..232..","...232....232...","....23222232....",".....233332.....","......2222......"],"Book":["..222222222222..",".23333333333332.",".23222222222222.",".23244444444222.",".23244422444222.",".23244233244222.",".23242333324222.",".23244333344222.",".23244333344222.",".23242333324222.",".23244233244222.",".23244422444222.",".23244444444222.",".23222222222222.",".23333333333332.","..222222222222.."],"Wind":["................",".......22222....","......2333332...","......2...2332..","...........232..","..222222222332..",".233333333332...","................","22222222222222..","233333333333332.",".............232","..222222222..232","..2333333332.232",".........232232.","........233222..",".......222......"],"Potion":[".....222222.....",".....233332.....",".....222222.....","......2332......","......2332......",".....233332.....","....23333332....","...2333333332...","...2322222232...","...2332222222...","...2332222222...","...2332222222...","...2322222222...","...2322222222...","....22222222....","................"],"Coin":[".....222222.....","...2233333322...","..233222222332..",".23222222222232.",".23222233222232.","2322223333222232","2322223322222232","2322223332222232","2322222333222232","2322222233222232","2322223333222232",".23222233222232.",".23222222222232.","..233222222332..","...2233333322...",".....222222....."],"Gem":[".......2........","......232.......",".....23322......","....2333222.....","...233332222....","..23333322222...","..23333322222...",".2333333222222..",".2333332222222..","..23333222222...","..23332222222...","...233222222....","....2322222.....",".....22222......","......222.......",".......2........"],"Person":[".....222222.....","....23333332....","....23333332....","....23333332....","....23333332....",".....233332.....","......2222......",".....222222.....","...2223333222...","..223333333322..",".23333333333332.",".23333333333332.",".23333333333332.",".23333333333332.",".22222222222222.","................"],"Bag":[".....222222.....","....23333332....","....23....32....","....23....32....","..222222222222..",".23333333333332.",".23333333333332.",".23322222222332.",".23322233222332.",".23322233222332.",".23322222222332.",".23333333333332.",".23333333333332.",".23333333333332.",".22222222222222.","................"],"Lock":["................",".....222222.....","....23333332....","...2332..2332...","...232....232...","...232....232...","..222222222222..","..233333333332..","..233333333332..","..233332233332..","..233332233332..","..233332233332..","..233333333332..","..233333333332..","..222222222222..","................"]};
function icon(parent,name,size,color="Gold",x=0,y=0){
 const lines=glyphs[name]||glyphs.Clover;
 const base=rgb(colors[color]||color),light=rgb(colors.Text);
 let body="";
 lines.forEach((line,yy)=>{let xx=0;while(xx<line.length){const ch=line[xx];let end=xx+1;while(end<line.length&&line[end]===ch)end++;if(ch!=="."){const c=ch==="4"?rgb(colors.Ink):ch==="3"?{r:base.r*.65+light.r*.35,g:base.g*.65+light.g*.35,b:base.b*.65+light.b*.35}:base;const hex="#"+[c.r,c.g,c.b].map(v=>Math.round(v*255).toString(16).padStart(2,"0")).join("");body+='<rect x="'+xx+'" y="'+yy+'" width="'+(end-xx)+'" height="1" fill="'+hex+'"/>';}xx=end;}});
 const n=track(figma.createNodeFromSvg('<svg xmlns="http://www.w3.org/2000/svg" width="'+size+'" height="'+size+'" viewBox="0 0 16 16">'+body+'</svg>'));n.name="Icon / "+name;parent.appendChild(n);n.x=x;n.y=y;return n;
}
const masters=box(page,"Components / Fusion counterparts",1020,970,"Track",2420,0);
label(masters,"CLOVERBOYZ / UI SYSTEM",880,40,18,"GoldLight","Regular",24,20,"LEFT",true);
label(masters,"Reusable HUD parts · editable vectors · colors mapped to Theme.luau",880,26,17,"Muted","Regular",24,60);
const resourceMasters={};
const resources=[["Health","100 / 100",1],["Mana","360 / 500",.72],["Stamina","95 / 100",.95]];
resources.forEach(([name,value,ratio],i)=>{
 const c=box(masters,"Resource / "+name,174,18,"Track",24,118+i*30,true);c.description="Compact resource bar; matches Components.Bar with Inline enabled.";
 rect(c,"Value fill",174*ratio,18,name);
 const shade=rect(c,"Contrast overlay",174,18,"Track");shade.opacity=.36;
 const r=row(c,"Label and value",164,18,4);r.x=5;
 const a=label(r,name.toUpperCase(),65,18,12,"Text","SemiBold");
 const b=label(r,value,95,18,14,"Text","Bold",0,0,"RIGHT");
 resourceMasters[name]=c;
});
const portrait=box(masters,"Portrait / Runtime avatar",54,76,"Ink",230,118,true);stroke(portrait,"Gold");
icon(portrait,"Clover",28,"Faint",13,9);
rect(portrait,"Divider",42,1,"GoldDim",6,54);
label(portrait,"LV. 12",54,20,15,"GoldLight","SemiBold",0,55,"CENTER");
portrait.description="Portrait slot. Runtime character is rendered in a Roblox ViewportFrame; the clover is the loading fallback.";
const status=box(masters,"HUD / Status",252,116,null,24,246,true);
const surface=box(status,"Resource surface",202,86,"Ink",50,0);stroke(surface,"GoldDim");
label(status,"ASTA",150,20,12,"Text","Regular",68,2,"LEFT",true);
icon(status,"Clover",16,"Gold",228,4);
resources.forEach(([name],i)=>instance(resourceMasters[name],status,68,24+i*20));
instance(portrait,status,0,8);
rect(status,"XP track",252,3,"Track",0,94);rect(status,"XP progress",193,3,"Gold",0,94);
label(status,"2,450 / 3,200 XP",252,18,14,"Text","SemiBold",0,100,"RIGHT");
status.description="252 × 116. Anchor bottom left. 16px safe inset in compact viewports.";
const slots={};
[["Sword","GoldLight"],["Wind","Green"],["Wind","Mana"],["Magic","Green"],["Potion","Health"]].forEach(([glyph,c],i)=>{
 const s=box(masters,"Ability / "+(i+1),44,52,null,24+i*58,398,true);
 const panel=box(s,"Surface",44,44,"Ink");stroke(panel,i===0?"GoldLight":"GoldDim");if(i===0)rect(panel,"Selected",44,2,"GoldLight");
 icon(panel,glyph,24,c,10,8);
 const key=box(s,"Key",20,20,"Track",12,34);stroke(key,i===0?"Gold":"Line");label(key,String(i+1),20,20,14,i===0?"GoldLight":"Muted","SemiBold",0,0,"CENTER");
 slots[i]=s;
});
const hotbar=box(masters,"HUD / Abilities",244,80,null,336,246,true);
label(hotbar,"IRON LONGSWORD",244,20,15,"GoldLight","SemiBold",0,0,"CENTER");
const slotRow=row(hotbar,"Five ability slots",244,54,6);slotRow.y=26;Object.values(slots).forEach(s=>instance(s,slotRow));
const menu=box(masters,"HUD / Menu",168,100,null,610,246,true);
const wallet=row(menu,"Currency",168,28,8);wallet.fills=[paint("Ink",.86)];wallet.paddingLeft=8;wallet.paddingRight=8;
icon(wallet,"Coin",16,"Gold");label(wallet,"1,250",58,24,16,"GoldLight","Bold");icon(wallet,"Gem",14,"Green");label(wallet,"24",26,24,16,"Text","Bold");
const nav=row(menu,"Shortcuts",168,62,6);nav.y=34;nav.counterAxisAlignItems="MIN";
[["Person","Stats","M"],["Book","Magic","G"],["Bag","Items","B"]].forEach(([glyph,title,key])=>{
 const c=box(nav,title,52,66);
 const button=box(c,"Button",52,44,"Ink");stroke(button,"GoldDim");icon(button,glyph,24,"GoldLight",14,6);
 label(button,key,13,16,12,"Muted","SemiBold",36,27,"CENTER");
 label(c,title,52,20,14,"Text","SemiBold",0,46,"CENTER");
});

const compactMenu=menu.clone();masters.appendChild(compactMenu);ids.push(compactMenu.id);compactMenu.name="HUD / Menu compact";compactMenu.x=610;compactMenu.y=390;compactMenu.resize(144,100);
const wr=compactMenu.findOne(n=>n.name==="Currency");wr.resize(144,28);wr.itemSpacing=4;
const nr=compactMenu.findOne(n=>n.name==="Shortcuts");nr.resize(144,66);
nr.children.forEach(n=>{n.resize(44,66);n.children.forEach(c=>{if(c.type==="FRAME"&&c.name==="Button"){c.resize(44,44);c.children.forEach(a=>{if(a.type==="FRAME")a.x=10;else if(a.type==="TEXT")a.x=28;});}else if(c.type==="TEXT")c.resize(44,20);});});
const compactHotbar=box(masters,"HUD / Abilities compact",204,80,null,336,396,true);
label(compactHotbar,"IRON LONGSWORD",204,20,15,"GoldLight","SemiBold",0,0,"CENTER");
const compactSlots=row(compactHotbar,"Five ability slots",204,54,6);compactSlots.y=26;
Object.values(slots).forEach((s,i)=>{const m=s.clone();masters.appendChild(m);ids.push(m.id);m.name="Ability compact / "+(i+1);m.x=24+i*48;m.y=462;m.resize(36,52);m.children.forEach(n=>{if(n.name==="Surface"){n.resize(36,44);n.children.forEach(a=>{if(a.type==="FRAME")a.x=6;else if(a.name==="Selected")a.resize(36,2);});}else if(n.name==="Key")n.x=8;});instance(m,compactSlots);});
const compass=box(masters,"HUD / Navigation",280,64,null,336,398,true);
const ribbon=box(compass,"Compass ribbon",280,30,"Ink");stroke(ribbon,"GoldDim");
["NW","N","NE"].forEach((s,i)=>label(ribbon,s,60,28,15,i===1?"GoldLight":"Muted","SemiBold",10+i*100,0,"CENTER"));
rect(ribbon,"Heading",2,7,"GoldLight",139,23);
label(compass,"HAGE VILLAGE",280,20,15,"Text","SemiBold",0,34,"CENTER");label(compass,"SAFE ZONE",280,18,12,"Green","SemiBold",0,54,"CENTER");
function background(root){root.fills=[{type:"GRADIENT_LINEAR",gradientTransform:[[0,1,0],[-1,0,1]],gradientStops:[{position:0,color:{...rgb("#73928D"),a:1}},{position:1,color:{...rgb("#405452"),a:1}}]}];}
function screen(name,w,h,x,y,compact=false){
 const root=box(page,name,w,h,null,x,y);root.clipsContent=true;background(root);
 const margin=compact?16:24;
 const hud=instance(status,root,margin,h-margin-116);
 const bar=instance(compact?compactHotbar:hotbar,root,compact?284:(w-244)/2,h-margin-80);
 instance(compact?compactMenu:menu,root,w-margin-(compact?144:168),h-margin-100);
 if(!compact)instance(compass,root,(w-280)/2,24);
 return root;
}
const desktop=screen("01 · HUD / Desktop · 1440 × 860",1440,860,0,0);
const compact=screen("02 · HUD / Compact · 730 × 640",730,640,1520,0,true);
label(page,"HUD / COMPACT",730,28,16,"GoldLight","Regular",1520,-50,"LEFT",true);
label(page,"HUD / DESKTOP",1440,28,16,"GoldLight","Regular",0,-50,"LEFT",true);
label(page,"Character viewport appears in Studio. Clover shown as fallback.",730,30,16,"Muted","Regular",1520,660);
const plus=box(masters,"Button / Add attribute",44,44,"Raised",24,526,true);stroke(plus,"Line");label(plus,"+",44,44,26,"GoldLight","SemiBold",0,0,"CENTER");
const attrMasters=[];
[["Heart","Vitality","Maximum health & recovery","24","Health"],["Sword","Strength","Physical damage","18","GoldLight"],["Magic","Magic","Mana capacity & spell power","32","Green"],["Shield","Defense","Damage resistance","16","Mana"]].forEach(([glyph,title,desc,value,color],i)=>{
 const a=box(masters,"Attribute / "+title,628,72,null,318,526+i*84,true);
 icon(a,glyph,28,color,4,22);
 const copy=row(a,"Attribute description",380,54,0,"VERTICAL");copy.x=48;copy.y=9;copy.counterAxisAlignItems="MIN";
 label(copy,title,380,28,21,"Text","SemiBold");label(copy,desc,380,23,16,"Muted");
 label(a,value,60,44,28,"Text","Bold",504,14,"RIGHT");instance(plus,a,584,14);
 rect(a,"Divider",628,1,"Line",0,71);attrMasters.push(a);
});
const stats=screen("03 · Character / Attributes · 1440 × 860",1440,860,0,1000);
const scrim=rect(stats,"Modal dim",1440,860,"Track");scrim.opacity=.62;
const panel=box(stats,"Character window",940,636,"Ink",24,24);stroke(panel,"GoldDim");rect(panel,"Top rule",940,2,"Gold",0,0);
icon(panel,"Clover",24,"Gold",24,24);label(panel,"CHARACTER",580,32,20,"Text","Regular",64,16,"LEFT",true);label(panel,"CLOVER KINGDOM",580,20,14,"Muted","SemiBold",64,48);
label(panel,"×",44,44,28,"Muted","Regular",880,16,"CENTER");
const tabs=row(panel,"Character navigation",892,44,12);tabs.x=24;tabs.y=80;
["Stats","Grimoire","Equipment"].forEach((s,i)=>{const t=box(tabs,s,(892-24)/3,44);label(t,s,t.width,42,18,i===0?"GoldLight":"Muted","SemiBold",0,0,"CENTER");if(i===0)rect(t,"Active",t.width,2,"Gold",0,42);});
const body=row(panel,"Character content",892,416,28);body.x=24;body.y=144;body.counterAxisAlignItems="MIN";
const identity=box(body,"Knight identity",236,416,"Panel");
label(identity,"MAGIC KNIGHT",204,24,14,"GoldLight","SemiBold",16,12);label(identity,"LV. 12",204,28,20,"Text","Bold",16,38);
icon(identity,"Clover",96,"Faint",70,100);
label(identity,"ASTA",204,30,16,"Text","Regular",16,226,"CENTER",true);
label(identity,"Black Bulls",204,28,20,"GoldLight","SemiBold",16,263,"CENTER");label(identity,"Junior Knight",204,24,16,"Muted","Regular",16,291,"CENTER");
rect(identity,"XP track",204,4,"Track",16,344);rect(identity,"XP value",156,4,"Gold",16,344);
label(identity,"2,450 / 3,200 XP",204,24,15,"Muted","SemiBold",16,356,"CENTER");
const attributes=row(body,"Attributes",628,416,8,"VERTICAL");attributes.counterAxisAlignItems="MIN";
const ah=row(attributes,"Heading",628,36,8);label(ah,"Attributes",400,36,24,"Text","SemiBold");label(ah,"3 points available",220,36,17,"GoldLight","SemiBold",0,0,"RIGHT");
attrMasters.forEach(a=>instance(a,attributes));
const combat=row(attributes,"Combat summary",628,40,24);label(combat,"ATK  36",140,28,16,"Muted","SemiBold");label(combat,"MAG  64",140,28,16,"Muted","SemiBold");label(combat,"DEF  16",140,28,16,"Muted","SemiBold");
rect(panel,"Footer divider",892,1,"Line",24,560);
label(panel,"Choose attributes, then apply your points.",610,44,16,"Muted","Regular",24,576);
const undo=box(panel,"Undo",88,44,null,668,576);label(undo,"Undo",88,44,17,"Muted","SemiBold",0,0,"CENTER");
const apply=box(panel,"Apply points",136,44,"Gold",780,576);label(apply,"Apply points",136,44,17,"Ink","SemiBold",0,0,"CENTER");
label(page,"CHARACTER / STATS",1440,28,16,"GoldLight","Regular",0,950,"LEFT",true);
figma.viewport.scrollAndZoomIntoView([desktop,compact]);
const all=page.findAll(()=>true);
const counts={};for(const n of all)counts[n.type]=(counts[n.type]||0)+1;
return {createdNodeIds:all.map(n=>n.id),mutatedNodeIds:[page.id],variableIds,collectionIds:[coll.id,space.id],screens:[desktop,compact,stats].map(n=>({id:n.id,name:n.name,width:n.width,height:n.height})),counts,fontFamilies:[...new Set(all.filter(n=>n.type==="TEXT").map(n=>n.fontName.family))],imageFilledNodes:all.filter(n=>"fills" in n&&Array.isArray(n.fills)&&n.fills.some(f=>f.type==="IMAGE")).map(n=>n.id)};
