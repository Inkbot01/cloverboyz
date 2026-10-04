from pathlib import Path
import json
import shutil

root = Path(__file__).resolve().parents[2]
manifest = json.loads((root / 'tmp/studio-ui/manifest.json').read_text())
out = root / 'src/shared/Assets/StudioImages'
out.mkdir(parents=True, exist_ok=True)
total = 0
modules = 0
for asset in manifest:
    data = (root / asset['encoded']).read_text().strip()
    assert len(data) == asset['bytes']
    name = asset['name']
    flat = out / f'{name}.luau'
    folder = out / name
    if folder.exists():
        shutil.rmtree(folder)
    if len(data) <= 60000:
        contents = f'return table.freeze({{ Width = {asset["width"]}, Height = {asset["height"]}, Data = [[{data}]] }})\n'
        flat.write_text(contents)
        total += len(contents)
        modules += 1
        continue
    flat.unlink(missing_ok=True)
    folder.mkdir()
    chunks = [data[start:start + 60000] for start in range(0, len(data), 60000)]
    entries = []
    for index, chunk in enumerate(chunks, 1):
        source = f'return [[{chunk}]]\n'
        (folder / f'Chunk{index}.luau').write_text(source)
        entries.append(f'\t\trequire(script.Chunk{index}),')
        total += len(source)
    contents = '\n'.join([
        'return table.freeze({',
        f'\tWidth = {asset["width"]},',
        f'\tHeight = {asset["height"]},',
        '\tData = table.concat({',
        *entries,
        '\t}),',
        '})',
        '',
    ])
    (folder / 'init.luau').write_text(contents)
    total += len(contents)
    modules += len(chunks) + 1
print(f'Bundled {len(manifest)} Studio images across {modules} modules ({total:,} bytes).')
