from pathlib import Path
from PIL import Image
import json
import base64
import ctypes

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tmp/studio-ui/buffers'
OUT.mkdir(parents=True, exist_ok=True)
manifest = []


def save(name, width, height, data):
    path = OUT / f'{name}.rgba'
    path.write_bytes(data)
    zstd = ctypes.CDLL('/opt/homebrew/lib/libzstd.dylib')
    zstd.ZSTD_compressBound.argtypes = [ctypes.c_size_t]
    zstd.ZSTD_compressBound.restype = ctypes.c_size_t
    zstd.ZSTD_compress.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int]
    zstd.ZSTD_compress.restype = ctypes.c_size_t
    output = ctypes.create_string_buffer(zstd.ZSTD_compressBound(len(data)))
    count = zstd.ZSTD_compress(output, len(output), data, len(data), 8)
    encoded = base64.b64encode(output.raw[:count]).decode()
    target = path.with_suffix('.rgba.b64')
    target.write_text(encoded)
    manifest.append({'name': name, 'width': width, 'height': height, 'path': str(path.relative_to(ROOT)), 'encoded': str(target.relative_to(ROOT)), 'bytes': len(encoded)})


for path in (ROOT / 'assets/interface/exports').glob('*.png'):
    with Image.open(path) as source:
        width, height = source.size
        rgba = source.convert('RGBA').tobytes()
        if path.stem != 'clover-icons-v1':
            save(path.stem, width, height, rgba)
        else:
            atlas = json.loads((ROOT / 'assets/interface/manifest.json').read_text())
            for index, (x0, y0, x1, y1) in enumerate(atlas['rectangles']):
                data = b''.join(rgba[(y*width+x0)*4:(y*width+x1)*4] for y in range(y0,y1))
                save(f'icon-{index+1}', x1-x0, y1-y0, data)

(OUT.parent / 'manifest.json').write_text(json.dumps(manifest, indent=2))
print(f'Serialized {len(manifest)} unchanged image regions for the Studio preview.')
