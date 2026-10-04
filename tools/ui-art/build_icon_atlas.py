from pathlib import Path
import json
import math

root = Path(__file__).resolve().parents[2]
manifest = json.loads((root / "assets/interface/manifest.json").read_text())
source_width, source_height = manifest["size"]
width, height = manifest["publishedSize"]
entries = []
for left, top, right, bottom in manifest["rectangles"]:
    x = math.floor(left * width / source_width + 0.5)
    y = math.floor(top * height / source_height + 0.5)
    crop_width = math.floor(right * width / source_width + 0.5) - x
    crop_height = math.floor(bottom * height / source_height + 0.5) - y
    assert x >= 0 and y >= 0 and crop_width > 0 and crop_height > 0
    assert x + crop_width <= width and y + crop_height <= height
    entries.append(f"\t\ttable.freeze({{ {x}, {y}, {crop_width}, {crop_height} }}),")
source = "\n".join([
    "return table.freeze({",
    f"\tWidth = {width},",
    f"\tHeight = {height},",
    "\tRectangles = table.freeze({",
    *entries,
    "\t}),",
    "})",
    "",
])
target = root / "src/shared/Assets/IconAtlas.luau"
target.write_text(source)
print(f"Generated {len(entries)} crops for the {width}x{height} published atlas.")
