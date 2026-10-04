from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json
import math
import sys

ROOT = Path(__file__).resolve().parents[2]
DIRECTORY = ROOT / (sys.argv[1] if len(sys.argv) > 1 else 'output/ui-previews/aligned')
FONT_DIR = Path('/Applications/RobloxStudio.app/Contents/Resources/content/fonts')
FONTS = {
    'Arcade': 'PressStart2P-Regular.ttf',
    'SourceSans': 'SourceSansPro-Regular.ttf',
    'SourceSansSemibold': 'SourceSansPro-Semibold.ttf',
    'SourceSansBold': 'SourceSansPro-Bold.ttf',
}
FONT_CACHE = {}


def font(name, size):
    key = (name, size)
    if key not in FONT_CACHE:
        FONT_CACHE[key] = ImageFont.truetype(str(FONT_DIR / FONTS.get(name, FONTS['SourceSans'])), max(1, round(size)))
    return FONT_CACHE[key]


def color(value, default=(255, 255, 255)):
    if not isinstance(value, dict):
        return default
    return value['r'], value['g'], value['b']


def dim(value, width, height, default=(0, 0)):
    if not isinstance(value, dict):
        return default
    return width * value.get('xs', 0) + value.get('xo', 0), height * value.get('ys', 0) + value.get('yo', 0)


def intersection(a, b):
    return max(a[0], b[0]), max(a[1], b[1]), min(a[2], b[2]), min(a[3], b[3])


def measured_size(node, width, height, scale=1):
    p = node['props']
    w, h = dim(p.get('Size'), width, height, (100, 100))
    if p.get('AutomaticSize') in ('X', 'XY') and node['class'] in ('TextLabel', 'TextButton', 'TextBox'):
        face = font(p.get('Font', 'SourceSans'), p.get('TextSize', 17) * scale)
        w = max(w, math.ceil(face.getlength(str(p.get('Text', '')))) / scale)
    for child in node['children']:
        if child['class'] == 'UISizeConstraint':
            lo, hi = child['props'].get('MinSize', {}), child['props'].get('MaxSize', {})
            w = max(lo.get('x', 0), min(hi.get('x', float('inf')), w))
            h = max(lo.get('y', 0), min(hi.get('y', float('inf')), h))
    return w, h


def child_layout(node, width, height, scale=1):
    padding = next((n['props'] for n in node['children'] if n['class'] == 'UIPadding'), {})
    def inset(name, extent):
        value = padding.get(name, {})
        return value.get('scale', 0) * extent + value.get('offset', 0)
    left, right = inset('PaddingLeft', width), inset('PaddingRight', width)
    top, bottom = inset('PaddingTop', height), inset('PaddingBottom', height)
    w, h = max(0, width-left-right), max(0, height-top-bottom)
    layout = next((n for n in node['children'] if n['class'] in ('UIListLayout', 'UIGridLayout')), None)
    positions = {}
    extent_x, extent_y = width, height
    if not layout:
        return (left, top, w, h), positions, (extent_x, extent_y)
    lp = layout['props']
    children = [n for n in node['children'] if not n['class'].startswith('UI') and n['props'].get('Visible', True)]
    children.sort(key=lambda n: n['props'].get('LayoutOrder', 0))
    horizontal = lp.get('FillDirection') == 'Horizontal'
    if layout['class'] == 'UIListLayout':
        sizes = [list(measured_size(n, w, h, scale)) for n in children]
        axis = 0 if horizontal else 1
        space = w if horizontal else h
        gap_spec = lp.get('Padding', {})
        gap = gap_spec.get('offset', 0) + space * gap_spec.get('scale', 0)
        flex = lp.get('HorizontalFlex' if horizontal else 'VerticalFlex', 'None')
        flexible = []
        for i, child in enumerate(children):
            item = next((n['props'] for n in child['children'] if n['class'] == 'UIFlexItem'), {})
            mode = item.get('FlexMode', 'None')
            if mode in ('Fill', 'Grow') or (not item and flex == 'Fill'):
                flexible.append(i)
        used = sum(s[axis] for s in sizes) + gap * max(0, len(sizes)-1)
        if flexible and space > used:
            for i in flexible:
                sizes[i][axis] += (space-used)/len(flexible)
            used = space
        align = lp.get('HorizontalAlignment' if horizontal else 'VerticalAlignment', 'Left' if horizontal else 'Top')
        cursor = (space-used)/2 if align == 'Center' else space-used if align in ('Right', 'Bottom') else 0
        for child, (cw, ch) in zip(children, sizes):
            cross = lp.get('VerticalAlignment' if horizontal else 'HorizontalAlignment', 'Top' if horizontal else 'Left')
            free = h-ch if horizontal else w-cw
            offset = free/2 if cross == 'Center' else free if cross in ('Right', 'Bottom') else 0
            positions[id(child)] = (left+(cursor if horizontal else offset), top+(offset if horizontal else cursor), cw, ch)
            cursor += (cw if horizontal else ch) + gap
        extent_x = max(width, left+used+right) if horizontal else width
        extent_y = height if horizontal else max(height, top+used+bottom)
    else:
        cw, ch = dim(lp.get('CellSize'), w, h)
        gx, gy = dim(lp.get('CellPadding'), w, h)
        columns = max(1, min(lp.get('FillDirectionMaxCells', 999), math.floor((w+gx)/(cw+gx))))
        for i, child in enumerate(children):
            positions[id(child)] = (left+(i%columns)*(cw+gx), top+(i//columns)*(ch+gy), cw, ch)
        extent_y = max(height, top+math.ceil(len(children)/columns)*(ch+gy)-gy+bottom)
    return (left, top, w, h), positions, (extent_x, extent_y)


class Renderer:
    def __init__(self, data):
        self.data = data
        self.density = data.get('density', 1)
        self.width, self.height = round(data['width'] * self.density), round(data['height'] * self.density)
        self.image = Image.new('RGBA', (self.width, self.height))
        self.diagnostics = []
        draw = ImageDraw.Draw(self.image)
        for y in range(self.height):
            t = y / self.height
            draw.line((0, y, self.width, y), fill=(round(48 - 25*t), round(65 - 33*t), round(68 - 30*t), 255))
        f = font('SourceSansSemibold', 16)
        title = 'CLOVERBOYZ  /  ' + data['page'].upper()
        bbox = draw.textbbox((0, 0), title, font=f)
        draw.text(((self.width - bbox[2]) / 2, self.height * .47), title, font=f, fill=(118, 141, 137, 115))
        subtitle = 'Component preview · avatar rendered in Studio'
        small = font('SourceSans', 14)
        box = draw.textbbox((0, 0), subtitle, font=small)
        draw.text(((self.width-box[2])/2, self.height*.47+25), subtitle, font=small, fill=(107, 125, 124, 115))

    def composite(self, layer, clip):
        clip = tuple(round(v) for v in clip)
        if clip[2] > clip[0] and clip[3] > clip[1]:
            cropped = layer.crop(clip)
            self.image.alpha_composite(cropped, (clip[0], clip[1]))

    def text(self, layer, props, bounds, path, clip):
        x, y, width, height = bounds
        text = props.get('Text', '')
        if not text and props.get('PlaceholderText'):
            text = props['PlaceholderText']
            text_color = color(props.get('PlaceholderColor3'), (137, 152, 146))
        else:
            text_color = color(props.get('TextColor3'), (240, 234, 219))
        if not text or width <= 0 or height <= 0:
            return
        draw = ImageDraw.Draw(layer)
        size = props.get('TextSize', 17)
        f = font(props.get('Font', 'SourceSans'), size)
        line_height = size * (1.22 if props.get('Font') != 'Arcade' else 1.3)
        wrapped = props.get('TextWrapped', False)
        lines = []
        for paragraph in str(text).split('\n'):
            if wrapped:
                current = ''
                for word in paragraph.split():
                    candidate = (current + ' ' + word).strip()
                    if draw.textlength(candidate, font=f) > width and current:
                        lines.append(current)
                        current = word
                    else:
                        current = candidate
                lines.append(current)
            else:
                lines.append(paragraph)
        max_lines = max(1, int((height + 4) / line_height))
        clipped = len(lines) > max_lines
        if clipped:
            lines = lines[:max_lines]
            lines[-1] += '…'
        for i, line in enumerate(lines):
            if draw.textlength(line, font=f) > width:
                clipped = True
                while line and draw.textlength(line + '…', font=f) > width:
                    line = line[:-1]
                lines[i] = line.rstrip('…') + '…'
        if clipped and intersection((x, y, x+width, y+height), clip)[3] > max(y, clip[1]):
            self.diagnostics.append({'issue': 'truncated_text', 'path': path, 'text': text, 'width': round(width), 'height': round(height), 'size': size})
        rendered_height = (len(lines)-1) * line_height + size
        vertical = props.get('TextYAlignment', 'Center')
        top = y if vertical == 'Top' else y + height - rendered_height if vertical == 'Bottom' else y+(height-rendered_height)/2
        for index, line in enumerate(lines):
            line_width = draw.textlength(line, font=f)
            align = props.get('TextXAlignment', 'Left')
            xx = x if align == 'Left' else x + width - line_width if align == 'Right' else x+(width-line_width)/2
            bb = draw.textbbox((0, 0), line, font=f)
            yy = top + index*line_height + (size-(bb[3]-bb[1]))/2 - bb[1]
            stroke = props.get('TextStrokeTransparency', 1)
            if stroke < 1:
                draw.text((round(xx), round(yy)), line, font=f, fill=text_color, stroke_width=1, stroke_fill=color(props.get('TextStrokeColor3'), (9, 15, 18)))
            else:
                draw.text((round(xx), round(yy)), line, font=f, fill=text_color)

    def node(self, node, parent, clip, path='', forced=None, parent_scale=1):
        props = node['props']
        cls = node['class']
        if cls.startswith('UI') or cls in ('WorldModel', 'Camera') or props.get('Visible', True) is False:
            return
        px, py, pw, ph = parent
        local_scale = next((n['props'].get('Scale', 1) for n in node['children'] if n['class'] == 'UIScale'), 1)
        scale = parent_scale * local_scale
        logical_width, logical_height = measured_size(node, pw / parent_scale, ph / parent_scale, scale)
        width, height = logical_width * scale, logical_height * scale
        ox, oy = dim(props.get('Position'), pw / parent_scale, ph / parent_scale)
        ox, oy = ox * parent_scale, oy * parent_scale
        anchor = props.get('AnchorPoint', {})
        x, y = px + ox - width*anchor.get('x', 0), py + oy - height*anchor.get('y', 0)
        if forced is not None:
            x, y, width, height = forced
            logical_width, logical_height = width / scale, height / scale
        if width < 0 or height < 0:
            self.diagnostics.append({'issue': 'negative_size', 'path': path, 'width': width, 'height': height})
            return
        path += '/' + props.get('Name', cls)
        own_clip = intersection(clip, (0, 0, self.width, self.height))
        if own_clip[0] >= own_clip[2] or own_clip[1] >= own_clip[3]:
            return
        layer = Image.new('RGBA', self.image.size)
        draw = ImageDraw.Draw(layer)
        transparency = props.get('BackgroundTransparency', 0)
        fill = (*color(props.get('BackgroundColor3'), (163, 162, 165)), round(255*(1-transparency)))
        box = (round(x), round(y), max(round(x), round(x+width)-1), max(round(y), round(y+height)-1))
        if width > 0 and height > 0 and transparency < 1:
            if props.get('Rotation') == 45:
                draw.polygon([(x+width/2,y-height*.2), (x+width*1.2,y+height/2), (x+width/2,y+height*1.2), (x-width*.2,y+height/2)], fill=fill)
            else:
                draw.rectangle(box, fill=fill)
        if cls in ('TextLabel', 'TextButton', 'TextBox'):
            text_props = dict(props, TextSize=props.get('TextSize', 17)*scale)
            self.text(layer, text_props, (x,y,width,height), path, own_clip)
        for child in node['children']:
            if child['class'] == 'UIStroke':
                p = child['props']
                if p.get('Transparency', 0) < 1 and width > 0 and height > 0:
                    draw.rectangle(box, outline=(*color(p.get('Color')), round(255*(1-p.get('Transparency', 0)))), width=max(1, round(p.get('Thickness', 1)*scale)))
        self.composite(layer, own_clip)
        child_clip = intersection(own_clip, (x, y, x+width, y+height)) if props.get('ClipsDescendants', False) or cls == 'ScrollingFrame' else own_clip
        children = [child for child in node['children'] if not child['class'].startswith('UI')]
        content, positions, (extent_x, extent_y) = child_layout(node, logical_width, logical_height, scale)
        left, top, inner_width, inner_height = content
        for child in sorted(children, key=lambda child: child['props'].get('ZIndex', 1)):
            placed = positions.get(id(child))
            forced_bounds = (x+placed[0]*scale, y+placed[1]*scale, placed[2]*scale, placed[3]*scale) if placed else None
            self.node(child, (x+left*scale,y+top*scale,inner_width*scale,inner_height*scale), child_clip, path, forced_bounds, scale)
            if not positions and child['props'].get('Visible',True):
                cx,cy = dim(child['props'].get('Position'),logical_width,logical_height)
                cw,ch = measured_size(child,logical_width,logical_height,scale)
                extent_x,extent_y = max(extent_x,cx+cw),max(extent_y,cy+ch)
        extent_x, extent_y = extent_x*scale, extent_y*scale
        if cls == 'ScrollingFrame' and props.get('ScrollBarThickness', 3) > 0:
            scroll = Image.new('RGBA', self.image.size)
            draw = ImageDraw.Draw(scroll)
            c = color(props.get('ScrollBarImageColor3'), (103,94,74))
            thickness = max(1, props.get('ScrollBarThickness',3)*scale)
            if extent_y > height and props.get('ScrollingDirection') != 'X':
                thumb = max(18,height*height/extent_y)
                draw.rectangle((x+width-thickness,y,x+width-1,y+thumb),fill=c)
            if extent_x > width and props.get('ScrollingDirection') == 'X':
                thumb = max(18,width*width/extent_x)
                draw.rectangle((x,y+height-thickness,x+thumb,y+height-1),fill=c)
            self.composite(scroll, child_clip)

    def render(self):
        self.node(self.data['tree'], (0,0,self.width,self.height), (0,0,self.width,self.height), parent_scale=self.density)
        self.image.convert('RGB').save(DIRECTORY / (self.data['name'] + '.png'))
        return self.diagnostics


if __name__ == '__main__':
    reports = {}
    pattern = sys.argv[2] if len(sys.argv) > 2 else '*.json'
    for file in sorted(DIRECTORY.glob(pattern)):
        if file.name == 'diagnostics.json' or file.name.endswith('.figma.json'):
            continue
        data = json.loads(file.read_text())
        if 'tree' not in data:
            continue
        reports[data['name']] = Renderer(data).render()
        print(f"Rendered {data['name']}: {len(reports[data['name']])} layout notices", flush=True)
    (DIRECTORY / 'diagnostics.json').write_text(json.dumps(reports, indent=2))
