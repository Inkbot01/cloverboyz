from pathlib import Path
import math
import json

ROOT = Path(__file__).resolve().parents[2]
PALETTE = {'1':'0b1217','2':'233039','3':'4b5964','4':'82919c','5':'bbc7cb','6':'edf1e5','7':'715633','8':'b38b47','9':'e1bb68','A':'fff0af','B':'194e42','C':'36856a','D':'65bb89','E':'b1edb2','F':'f4d7ac','G':'c39573','H':'754c43','I':'632f42','J':'b74d59','K':'ed7377','L':'b2dadf','M':'8f78b0','N':'51405f','O':'30536a','P':'5f9fc0'}
sprites = {}

class Grid:
    def __init__(self):
        self.rows = [['.']*32 for _ in range(32)]
    def dot(self,x,y,c):
        if 0 <= x < 32 and 0 <= y < 32:
            self.rows[y][x] = c
    def rect(self,x,y,w,h,c):
        for yy in range(y,y+h):
            for xx in range(x,x+w):
                self.dot(xx,yy,c)
    def polygon(self,points,c):
        for y in range(32):
            for x in range(32):
                px,py=x+.5,y+.5
                inside=False
                previous=points[-1]
                for current in points:
                    x1,y1=previous
                    x2,y2=current
                    if (y1>py)!=(y2>py) and px < (x2-x1)*(py-y1)/(y2-y1)+x1:
                        inside=not inside
                    previous=current
                if inside:
                    self.dot(x,y,c)
    def line(self,x1,y1,x2,y2,c,width=1):
        count=max(abs(x2-x1),abs(y2-y1),1)
        for i in range(count+1):
            x=round(x1+(x2-x1)*i/count)
            y=round(y1+(y2-y1)*i/count)
            self.rect(x-width//2,y-width//2,width,width,c)
    def save(self,name):
        sprites[name]=[''.join(row) for row in self.rows]

g=Grid()
g.polygon([(5,28),(3,26),(10,19),(8,17),(10,15),(13,17),(25,3),(29,2),(30,6),(16,20),(18,23),(16,25),(13,22)],'1')
g.polygon([(12,17),(25,4),(28,3),(29,6),(15,20)],'3')
g.line(14,17,27,4,'5')
g.line(15,18,28,5,'4')
g.line(10,16,17,23,'8',2)
g.dot(10,16,'A')
g.line(5,26,12,20,'4',2)
g.line(5,27,11,21,'2')
for x,y in [(7,24),(9,22)]: g.dot(x,y,'9')
g.rect(3,27,3,2,'8')
g.save('Sword')

for name,c1,c2,c3 in [('Wind','C','D','E'),('Gale','O','P','L')]:
    g=Grid()
    for arm in range(3):
        previous=None
        for step in range(46):
            t=step/45
            radius=2+11*t
            angle=arm*math.tau/3+t*math.pi*1.55
            x,y=round(16+radius*math.cos(angle)),round(16+radius*math.sin(angle))
            if previous:
                g.line(*previous,x,y,'B' if name=='Wind' else 'O',4)
            previous=x,y
        previous=None
        for step in range(42):
            t=step/45
            radius=2+11*t
            angle=arm*math.tau/3+t*math.pi*1.55
            x,y=round(16+radius*math.cos(angle)),round(16+radius*math.sin(angle))
            if previous:
                g.line(*previous,x,y,c2,2)
            g.dot(x,y,c3 if step%5<3 else c1)
            previous=x,y
    for x,y in [(6,5),(27,10),(23,28),(5,22)]:g.dot(x,y,c2)
    g.save(name)

g=Grid()
g.polygon([(7,3),(25,2),(28,27),(10,30),(5,27),(4,7)],'1')
g.polygon([(8,5),(24,4),(26,26),(10,28),(7,26),(6,7)],'7')
g.polygon([(10,6),(23,5),(25,25),(11,27)],'2')
g.line(8,7,10,26,'9')
g.line(11,7,22,6,'8')
g.line(12,25,23,24,'8')
g.rect(21,15,5,3,'8');g.dot(24,16,'A')
for x,y in [(13,12),(18,11),(13,17),(18,16)]:
    g.rect(x,y,3,3,'9');g.dot(x+1,y,'A')
g.rect(16,14,2,6,'9');g.rect(17,20,1,3,'8')
g.save('Grimoire')

g=Grid()
for flip in [False,True]:
    points=[(4,5),(8,4),(26,25),(24,28),(22,27),(4,8)]
    if flip:points=[(31-x,y) for x,y in points]
    g.polygon(points,'N')
    x1,x2=(6,24) if not flip else (25,7)
    g.line(x1,6,x2,26,'M',2)
    g.line(x1+1,6,x2+1,26,'3')
g.save('Magic')

g=Grid()
g.rect(12,2,8,5,'1');g.rect(13,2,6,3,'8');g.rect(13,2,6,1,'F')
g.polygon([(12,6),(20,6),(20,12),(25,18),(25,27),(22,30),(10,30),(7,27),(7,18),(12,12)],'1')
g.polygon([(13,7),(19,7),(19,13),(23,18),(23,26),(21,28),(11,28),(9,26),(9,18),(13,13)],'4')
g.polygon([(11,19),(21,19),(22,21),(22,26),(20,27),(11,27),(10,25),(10,21)],'J')
g.rect(11,19,10,2,'K');g.rect(12,8,2,6,'L');g.line(10,19,10,24,'6')
g.rect(13,6,7,2,'5');g.dot(20,23,'K')
g.save('Potion')

g=Grid()
g.polygon([(9,3),(23,3),(28,8),(28,24),(23,29),(9,29),(4,24),(4,8)],'1')
g.polygon([(10,4),(22,4),(27,9),(27,23),(22,28),(10,28),(5,23),(5,9)],'8')
g.polygon([(10,5),(21,5),(25,9),(25,22),(21,26),(10,26),(6,22),(6,9)],'A')
g.polygon([(11,7),(21,7),(24,10),(24,21),(21,24),(11,24),(8,21),(8,10)],'9')
g.line(11,8,20,8,'6');g.rect(14,10,3,13,'8');g.rect(11,12,10,2,'8');g.rect(11,18,10,2,'8')
g.save('Coin')

g=Grid()
g.polygon([(17,1),(27,10),(21,28),(12,31),(5,21),(10,5)],'1')
g.polygon([(17,3),(25,11),(20,26),(12,29),(7,21),(11,6)],'C')
g.polygon([(17,4),(19,12),(13,27),(12,9)],'E')
g.polygon([(19,12),(24,11),(20,25),(14,28)],'D')
g.line(17,5,13,25,'6');g.save('Gem')

g=Grid()
g.polygon([(12,4),(20,4),(22,7),(22,12),(19,15),(19,18),(25,21),(28,26),(28,29),(4,29),(4,26),(7,21),(13,18),(13,15),(10,12),(10,7)],'7')
g.polygon([(12,5),(19,5),(21,8),(21,12),(18,15),(14,15),(11,12),(11,8)],'A')
g.polygon([(13,18),(18,18),(24,22),(26,27),(6,27),(8,22)],'9')
g.line(8,23,13,20,'A');g.save('Person')

g=Grid()
g.polygon([(3,7),(13,5),(16,7),(19,5),(29,7),(29,27),(19,25),(16,27),(13,25),(3,27)],'7')
g.polygon([(5,8),(13,7),(15,9),(15,25),(12,23),(5,24)],'A')
g.polygon([(17,9),(20,7),(27,8),(27,24),(20,23),(17,25)],'9')
g.line(16,8,16,27,'2')
for y in [11,15,19]:
    g.line(7,y,12,y-1,'8');g.line(20,y,25,y+1,'7')
g.save('Book')

g=Grid()
g.rect(11,3,10,8,'8');g.rect(13,5,6,6,'1')
g.polygon([(9,10),(23,10),(27,15),(27,28),(24,30),(8,30),(5,28),(5,15)],'7')
g.rect(8,13,16,14,'9');g.rect(9,12,14,8,'A');g.rect(14,19,4,5,'8');g.rect(15,20,2,3,'6')
g.line(7,16,7,26,'8');g.line(24,16,24,26,'7');g.save('Bag')

g=Grid()
g.polygon([(6,31),(7,26),(13,23),(19,23),(26,26),(28,31)],'1')
g.polygon([(7,27),(12,25),(16,29),(20,25),(26,28),(27,31),(6,31)],'8')
g.polygon([(9,25),(13,24),(16,27),(19,24),(23,26),(24,31),(8,31)],'2')
g.rect(13,21,7,5,'G');g.rect(7,12,20,9,'G')
g.polygon([(8,12),(25,12),(25,22),(21,25),(12,25),(8,22)],'F')
g.rect(10,16,5,5,'6');g.rect(20,16,4,5,'6')
g.rect(12,17,2,4,'C');g.rect(20,17,2,4,'C')
g.dot(13,17,'1');g.dot(21,17,'1');g.line(16,23,19,23,'H')
g.polygon([(5,15),(3,9),(7,9),(6,3),(11,6),(13,0),(17,5),(21,1),(22,7),(28,4),(27,10),(31,10),(26,16),(22,12),(19,14),(16,10),(12,14),(10,11)],'3')
g.polygon([(5,10),(9,10),(8,5),(12,8),(14,3),(17,8),(20,5),(20,10),(25,7),(24,12),(28,12),(25,16),(21,12),(18,14),(15,10),(11,14),(9,12),(7,15)],'5')
g.line(10,8,14,11,'6');g.line(18,8,20,10,'6');g.dot(23,12,'6')
g.rect(7,13,19,3,'1');g.rect(8,13,10,1,'3')
g.rect(21,13,3,2,'9');g.dot(22,12,'A')
g.save('Knight')

out=['local Sprites = {','\tPalette = {']
for key,value in PALETTE.items():
    rgb=tuple(int(value[i:i+2],16) for i in (0,2,4))
    out.append(f'\t\t["{key}"] = Color3.fromRGB({rgb[0]}, {rgb[1]}, {rgb[2]}),')
out+=['\t},','\tPatterns = {']
for name,rows in sprites.items():
    out.append(f'\t\t{name} = {{')
    out.extend(f'\t\t\t"{row}",' for row in rows)
    out.append('\t\t},')
out+=['\t},','}','', 'return table.freeze(Sprites)', '']
(ROOT/'src/client/Interface/HudSprites.luau').write_text('\n'.join(out))
(ROOT/'output/ui-previews/reference/sprites.json').write_text(json.dumps({'palette':PALETTE,'patterns':sprites}))
print(f'Built {len(sprites)} sprites')
