from pathlib import Path
from shutil import copy2

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/ui'
OUT.mkdir(parents=True, exist_ok=True)


def contour(size, inset, cut):
    lo, hi = inset, size - inset
    a, b = lo + cut, hi - cut
    step = max(1, cut // 2)
    return f'M {a} {lo} H {b} V {lo+step} H {hi-step} V {a} H {hi} V {b} H {hi-step} V {hi-step} H {b} V {hi} H {a} V {hi-step} H {lo+step} V {b} H {lo} V {a} H {lo+step} V {lo+step} H {a} Z'


def ring(size, inset, cut, thickness, color):
    outer = contour(size, inset, cut)
    inner = contour(size, inset + thickness, max(0, cut - thickness))
    return f'<path fill="{color}" fill-rule="evenodd" d="{outer} {inner}"/>'


def save(name, size, paths):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}" shape-rendering="crispEdges">' + ''.join(paths) + '</svg>'
    (OUT / f'{name}.svg').write_text(svg)


for name, size, cut in [('control', 32, 4), ('portrait', 96, 16), ('window', 96, 8), ('track', 16, 2)]:
    save(f'{name}-fill', size, [f'<path fill="#fff" d="{contour(size, 0, cut)}"/>'])
    paths = [ring(size, 0, cut, 1, '#05090b'), ring(size, 1, max(0, cut-1), 1, '#fff')]
    if name != 'track':
        paths.append(ring(size, 2, max(0, cut-2), 1, '#454545'))
    if name in ('window', 'portrait'):
        paths.append(ring(size, 4, max(0, cut-4), 1, '#8c8c8c'))
    if name == 'window':
        for transform in ['', f'translate({size} 0) scale(-1 1)', f'translate(0 {size}) scale(1 -1)', f'translate({size} {size}) scale(-1 -1)']:
            paths.append(f'<g transform="{transform}" fill="#fff"><path d="M 8 6 H 18 V 8 H 10 V 18 H 8 Z"/><rect x="14" y="12" width="4" height="4"/><rect x="12" y="14" width="8" height="2"/><rect x="14" y="12" width="2" height="8"/></g>')
    save(f'{name}-trim', size, paths)

copy2(ROOT / 'assets/interface/clover-icons-v1.png', OUT / 'clover-icons-v1.png')
print('Prepared the original SVG skin sources and clover icon atlas.')
