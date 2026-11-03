import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "assets/interface/customization/v1"
OUT = ROOT / "tmp/customization-transfer"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(PACK / "clover-customization-v1.blend"))
manifest = json.loads((PACK / "exports/manifest.json").read_text())
for collection in bpy.data.collections:
    collection.hide_viewport = False
bpy.context.view_layer.update()
palette = list(manifest["palette"]["colors"].values())
centers = manifest["coordinates"]["bodyCenters"]
summary = []
fittings = {}
for asset in manifest["assets"]:
    collection = bpy.data.collections[asset["id"]]
    parts = []
    for obj in collection.objects:
        segment = obj.get("body_segment") or ("Head" if asset["category"] == "Hair" or "headband" in asset["id"] else "Torso")
        reference = centers[segment]
        world = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
        low = Vector([min(v[i] for v in world) for i in range(3)])
        high = Vector([max(v[i] for v in world) for i in range(3)])
        center = (low + high) / 2
        positions = [[round(v.x-center.x,6),round(v.z-center.z,6),round(v.y-center.y,6)] for v in world]
        obj.data.calc_loop_triangles()
        faces=[]
        for face in obj.data.loop_triangles:
            uv = obj.data.uv_layers.active.data[face.loops[0]].uv
            index = min(3, int(uv.y*4))*4 + min(3, int(uv.x*4))
            normal = obj.matrix_world.to_3x3() @ face.normal
            faces.append([face.vertices[0]+1,face.vertices[2]+1,face.vertices[1]+1,index+1,
                          round(normal.x,6),round(normal.z,6),round(normal.y,6)])
        parts.append({"segment":segment,"positions":positions,"faces":faces,
            "offset":[round(center.x-reference[0],6),round(center.z-reference[2],6),round(center.y-reference[1],6)],
            "size":[round(high.x-low.x,6),round(high.z-low.z,6),round(high.y-low.y,6)],
            "referenceSize":[1.4,1,1] if segment=="Head" else ([2,2,1] if segment=="Torso" else [1,2,1])})
    data={"id":asset["id"],"category":asset["category"],"palette":palette,"parts":parts}
    fittings[asset["id"]] = {"category":asset["category"], "parts":[{k:v for k,v in part.items() if k not in ("positions","faces")} for part in parts]}
    (OUT/(asset["id"]+".json")).write_text(json.dumps(data,separators=(",",":")),encoding="utf-8")
    summary.append({"id":asset["id"],"parts":len(parts)})
(OUT/"index.json").write_text(json.dumps(summary),encoding="utf-8")
(PACK/"fitting.json").write_text(json.dumps(fittings,indent=2),encoding="utf-8")
print("EXPORTED",len(summary),"assets")
