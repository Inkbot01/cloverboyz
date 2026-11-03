import bpy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "assets/interface/customization/v1"
bpy.ops.wm.open_mainfile(filepath=str(PACK / "clover-customization-v1.blend"))
manifest = json.loads((PACK / "exports/manifest.json").read_text())
bpy.ops.object.select_all(action="DESELECT")
for asset in manifest["assets"]:
    collection = bpy.data.collections[asset["id"]]
    collection.hide_viewport = False
    collection.hide_render = False
    for obj in collection.objects:
        segment = obj.get("body_segment") or "Handle"
        obj.name = asset["id"] + "__" + segment.replace(" ", "_")
        obj.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(PACK / "clover-customization-import.fbx"),use_selection=True,
    object_types={"MESH"},axis_forward="-Z",axis_up="Y",global_scale=1,
    apply_unit_scale=False,bake_anim=False,use_mesh_modifiers=True,
    mesh_smooth_type="OFF",path_mode="COPY",embed_textures=True)
print("PACKAGED", sum(len(asset["parts"]) for asset in manifest["assets"]), "mesh parts")
