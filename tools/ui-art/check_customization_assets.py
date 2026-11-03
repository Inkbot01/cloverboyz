import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "assets/interface/customization/v1"
manifest = json.loads((PACK / "exports/manifest.json").read_text(encoding="utf-8"))
results = []

for asset in manifest["assets"]:
    expected_parts = 5 if asset["category"] == "Outfit" else 1
    assert len(asset["parts"]) == expected_parts, asset["id"]
    if asset["category"] == "Outfit":
        assert {part["bodySegment"] for part in asset["parts"]} == {
            "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"
        }, asset["id"]
    assert asset["robloxAssetId"] is None
    for format in ("gltf", "fbx"):
        path = PACK / asset[format]
        assert path.is_file() and path.stat().st_size > 0, path
        if format == "gltf":
            document = json.loads(path.read_text(encoding="utf-8"))
            for resource in document.get("buffers", []) + document.get("images", []):
                assert (path.parent / resource["uri"]).is_file(), resource
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        if format == "gltf":
            bpy.ops.import_scene.gltf(filepath=str(path))
        else:
            bpy.ops.import_scene.fbx(filepath=str(path))
        objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
        assert len(objects) == expected_parts, (asset["id"], format, len(objects))
        triangles = 0
        bounds = []
        for obj in objects:
            obj.data.calc_loop_triangles()
            triangles += len(obj.data.loop_triangles)
            assert all(triangle.area > 1e-10 for triangle in obj.data.loop_triangles), (asset["id"], "degenerate face")
            assert obj.data.uv_layers, (asset["id"], "missing UVs")
            assert obj.data.materials, (asset["id"], "missing material")
            assert all(math.isfinite(c) for vertex in obj.data.vertices for c in vertex.co)
            assert all(0 <= c <= 1 for uv in obj.data.uv_layers[0].data for c in uv.uv)
            bounds.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
        assert triangles == asset["triangles"], (asset["id"], format, triangles, asset["triangles"])
        for i in range(3):
            assert abs(min(v[i] for v in bounds) - asset["bounds"]["min"][i]) < .002, (asset["id"], format, "minimum scale or axis mismatch")
            assert abs(max(v[i] for v in bounds) - asset["bounds"]["max"][i]) < .002, (asset["id"], format, "maximum scale or axis mismatch")
        results.append({"id": asset["id"], "format": format, "parts": len(objects), "triangles": triangles, "passed": True})

image = bpy.data.images.load(str(PACK / manifest["face"]["file"]), check_existing=False)
assert image.channels == 4
alpha = list(image.pixels)[3::4]
assert min(alpha) == 0 and max(alpha) == 1
transparent = sum(value == 0 for value in alpha) / len(alpha)
assert transparent > .5
report = {
    "status": "passed",
    "checks": "20 Blender FBX/glTF reimports: part counts, triangle counts, nondegenerate faces, finite vertices, bounded UVs, materials, resource files and axis/scale-preserving bounds",
    "face": {"channels": 4, "size": list(image.size), "transparentFraction": transparent},
    "results": results,
    "notVerified": ["Roblox Studio import", "custom rig exact fit", "attachment offsets", "animation clipping", "cloud upload and moderation"]
}
(PACK / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print("CUSTOMIZATION_VERIFICATION_PASSED " + str(len(results)) + " imports")
