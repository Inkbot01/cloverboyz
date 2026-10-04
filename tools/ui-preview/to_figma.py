import json
import sys
from pathlib import Path
from render import measured_size, child_layout

ROOT=Path(__file__).resolve().parents[2]
source=ROOT / sys.argv[1]
data=json.loads(source.read_text())


def dim(value,w,h,default=(0,0)):
    if not isinstance(value,dict):return default
    return value.get('xs',0)*w+value.get('xo',0),value.get('ys',0)*h+value.get('yo',0)


def rgb(value):
    if not value:return '#11181b'
    return '#'+''.join(f'{value[c]:02x}' for c in ('r','g','b'))


def convert(node,w,h,forced=None,parent_scale=1):
    p=node['props']
    if not p.get('Visible',True) or node['class'] in ('WorldModel','Camera','ViewportFrame') or node['class'].startswith('UI'):
        return None
    local_scale=next((n['props'].get('Scale',1) for n in node['children'] if n['class']=='UIScale'),1)
    scale=parent_scale*local_scale
    lw,lh=measured_size(node,w/parent_scale,h/parent_scale,scale)
    ww,hh=lw*scale,lh*scale
    x,y=dim(p.get('Position'),w/parent_scale,h/parent_scale)
    x,y=x*parent_scale,y*parent_scale
    a=p.get('AnchorPoint',{})
    x-=a.get('x',0)*ww
    y-=a.get('y',0)*hh
    if forced is not None:
        x,y,ww,hh=forced
        lw,lh=ww/scale,hh/scale
    item={'name':p.get('Name',node['class']),'kind':node['class'],'x':round(x,3),'y':round(y,3),'w':round(ww,3),'h':round(hh,3)}
    if item['name'].startswith('Art_') or item['name']=='Icon':
        rects=[]
        for child in node['children']:
            cp=child['props']
            if cp.get('Name')!='Pixel':continue
            xx,yy=dim(cp.get('Position'),ww,hh)
            cw,ch=dim(cp.get('Size'),ww,hh)
            rects.append(f'<path d="M{xx:g} {yy:g}h{cw:g}v{ch:g}h{-cw:g}Z" fill="{rgb(cp.get("BackgroundColor3"))}"/>')
        if rects:
            item['svg']=f'<svg xmlns="http://www.w3.org/2000/svg" width="{ww:g}" height="{hh:g}" viewBox="0 0 {ww:g} {hh:g}">'+''.join(rects)+'</svg>'
            return item
    if p.get('BackgroundTransparency',0)<1:
        item['fill']=rgb(p.get('BackgroundColor3'))
        item['opacity']=1-p.get('BackgroundTransparency',0)
    if p.get('Text'):
        item.update(text=p['Text'],font=p.get('Font','SourceSans'),size=p.get('TextSize',17)*scale,color=rgb(p.get('TextColor3')),align=p.get('TextXAlignment','Left'),valign=p.get('TextYAlignment','Center'),wrapped=p.get('TextWrapped',False))
    item['clip']=p.get('ClipsDescendants',False)
    item['children']=[]
    contours=[]
    content,positions,_=child_layout(node,lw,lh,scale)
    left,top,iw,ih=content
    for child in sorted(node['children'],key=lambda c:c['props'].get('ZIndex',1)):
        placed=positions.get(id(child))
        placed=tuple(v*scale for v in placed) if placed else None
        cc=convert(child,iw*scale,ih*scale,placed,scale)
        if cc:
            if placed is None:
                cc['x']+=left*scale
                cc['y']+=top*scale
            if cc['name']=='Contour':contours.append(cc)
            else:item['children'].append(cc)
    if contours:
        paths=''.join(f'<path d="M{c["x"]:g} {c["y"]:g}h{c["w"]:g}v{c["h"]:g}h{-c["w"]:g}Z" fill="{c["fill"]}"/>' for c in contours if c['w']>0 and c['h']>0)
        item['children'].insert(0,{'name':'Pixel contour','kind':'Frame','x':0,'y':0,'w':ww,'h':hh,'svg':f'<svg xmlns="http://www.w3.org/2000/svg" width="{ww:g}" height="{hh:g}" viewBox="0 0 {ww:g} {hh:g}">'+paths+'</svg>'})
    return item


density=data.get('density',1)
width,height=data['width']*density,data['height']*density
result={'width':width,'height':height,'name':data['name'],'tree':convert(data['tree'],width,height,parent_scale=density)}
path=source.with_suffix('.figma.json')
path.write_text(json.dumps(result,separators=(',',':')))
print(path)
