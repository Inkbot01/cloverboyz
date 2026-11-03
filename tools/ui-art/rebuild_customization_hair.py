import bpy
import bmesh
import json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/interface/customization/v1"
OUT = ROOT / "assets/interface/customization/v2"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / "clover-customization-v1.blend"))
for collection in bpy.data.collections:
    collection.hide_viewport = False
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0
palette = bpy.data.materials["CloverPalette"]
colors = list(json.loads((SOURCE / "exports/manifest.json").read_text())["palette"]["colors"])
objects = []
vertices = []
faces = []
tones = []


def surface(points, polygons, color):
    start = len(vertices)
    vertices.extend(points)
    faces.extend([tuple(start + index for index in face) for face in polygons])
    tones.extend([colors.index(color)] * len(polygons))


def lock(centers, widths, depths, color):
    points = []
    for (x, y, z), width, depth in zip(centers, widths, depths):
        points.extend([(x-width,y-depth,z),(x+width,y-depth,z),(x+width,y+depth,z),(x-width,y+depth,z)])
    polygons = [(3,2,1,0)]
    for index in range(len(centers)-1):
        a, b = index*4, (index+1)*4
        polygons.extend([(a+j,a+(j+1)%4,b+(j+1)%4,b+j) for j in range(4)])
    polygons.append(tuple(range(len(points)-4,len(points))))
    surface(points, polygons, color)


def scalp(color):
    outline = [(-.655,-.59),(.655,-.59),(.69,-.555),(.69,.555),(.655,.59),(-.655,.59),(-.69,.555),(-.69,-.555)]
    lower = [.28,.28,.13,-.34,-.38,-.38,-.34,.13]
    points = [(x,y,z) for (x,y),z in zip(outline,lower)]
    points += [(x,y,.54) for x,y in outline]
    points += [(x*.81,y*.81,.69) for x,y in outline]
    polygons = []
    for ring in range(2):
        for i in range(8):
            a, b = ring*8+i, ring*8+(i+1)%8
            polygons.append((a,b,b+8,a+8))
    polygons.append(tuple(range(16,24)))
    surface(points,polygons,color)


def finish(identifier):
    data = bpy.data.meshes.new(identifier)
    data.from_pydata(vertices, [], faces)
    data.update()
    data.materials.append(palette)
    uv = data.uv_layers.new(name="Palette")
    for face, tone in zip(data.polygons, tones):
        point = ((tone % 4 + .5)/4, (tone // 4 + .5)/4)
        for loop in face.loop_indices:
            uv.data[loop].uv = point
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new(identifier+"__Handle", data)
    bpy.context.scene.collection.objects.link(obj)
    obj["body_segment"] = "Head"
    objects.append(obj)
    vertices.clear()
    faces.clear()
    tones.clear()


scalp("silver_dark")
for x,tip,height in [(-.52,-.70,.86),(-.27,-.36,1.04),(0,.07,1.13),(.29,.47,1.00),(.52,.73,.81)]:
    lock([(x,.05,.51),(x,.04,.72),(tip,.06,height)], [.22,.19,.018],[.28,.22,.02],"silver")
for x,tip,z in [(-.51,-.56,.03),(-.28,-.20,.09),(-.03,.04,-.04),(.23,.32,.13),(.47,.53,.04)]:
    lock([(x,-.51,.59),(x,-.635,.32),(tip,-.64,z)],[.18,.15,.016],[.09,.085,.014],"silver")
for side in (-1,1):
    lock([(side*.63,.06,.42),(side*.70,.05,.04),(side*.66,.06,-.25)],[.095,.075,.016],[.29,.23,.018],"silver_dark")
finish("hair-iron-spikes-v1")

scalp("shadow")
for x,height in [(-.48,.81),(-.20,.88),(.09,.85),(.37,.76)]:
    lock([(x,.06,.51),(x+.06,-.01,height),(x+.34,-.07,height+.035)],[.24,.21,.016],[.32,.23,.015],"ink")
for x,tip,z in [(-.49,-.31,.01),(-.26,-.02,-.12),(-.02,.22,-.04),(.22,.43,.10),(.46,.59,.18)]:
    lock([(x-.06,-.50,.57),(x+.03,-.64,.30),(tip,-.65,z)],[.20,.17,.015],[.09,.075,.015],"ink")
for side in (-1,1):
    lock([(side*.65,.03,.39),(side*.70,.0,-.05),(side*.66,-.02,-.29)],[.085,.065,.015],[.26,.21,.012],"ink")
finish("hair-wind-swept-v1")

scalp("auburn")
for side in (-1,1):
    lock([(side*.16,-.53,.64),(side*.43,-.64,.36),(side*.56,-.635,-.08)],[.19,.18,.036],[.09,.085,.022],"auburn_light")
    lock([(side*.63,-.06,.37),(side*.70,-.10,-.09),(side*.66,-.10,-.38)],[.10,.075,.018],[.26,.18,.015],"auburn")
lock([(0,.57,.43),(0,.69,.43)],[.21,.21],[.12,.12],"brass")
for x,shade in [(-.20,"auburn_light"),(.03,"auburn"),(.23,"auburn")]:
    lock([(x,.61,.49),(x,.90,.22),(x+.03,.95,-.32),(x-.03,.81,-.97)],[.21,.24,.18,.025],[.19,.20,.16,.02],shade)
finish("hair-ember-ponytail-v1")

fittings = {}
for obj in objects:
    tree = BVHTree.FromPolygons([v.co for v in obj.data.vertices], [list(p.vertices) for p in obj.data.polygons])
    rays = []
    for side in (-1,1):
        for depth in (-.50,.50):
            rays.append(((side*2,depth,.40),(-side,0,0),0,side*.625,side))
            rays.append(((side*.60,depth,2),(0,0,-1),2,.50,1))
        rays.append(((side*.60,-2,.40),(0,1,0),1,-.525,-1))
    for origin,direction,axis,limit,sign in rays:
        hit,normal,index,distance = tree.ray_cast(Vector(origin),Vector(direction))
        assert hit is not None and sign*(hit[axis]-limit)>0, (obj.name,"Exposed head corner",origin)
    values = [vertex.co for vertex in obj.data.vertices]
    low = Vector([min(v[i] for v in values) for i in range(3)])
    high = Vector([max(v[i] for v in values) for i in range(3)])
    center = (low+high)/2
    identifier = obj.name.split("__")[0]
    fittings[identifier] = {"category":"Hair","parts":[{"segment":"Head",
        "size":[high.x-low.x,high.z-low.z,high.y-low.y],
        "offset":[center.x,center.z,center.y],"referenceSize":[1.25,1,1.05]}]}
    for vertex in values:
        assert all(abs(component)<2 for component in vertex)
(OUT/"fitting.json").write_text(json.dumps(fittings,indent=2),encoding="utf-8")
bpy.ops.object.select_all(action="DESELECT")
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"clover-hair-v2.blend"))
bpy.ops.export_scene.fbx(filepath=str(OUT/"clover-hair-v2.fbx"),use_selection=True,
    object_types={"MESH"},axis_forward="-Z",axis_up="Y",global_scale=1,
    apply_unit_scale=False,bake_anim=False,use_mesh_modifiers=True,
    mesh_smooth_type="OFF",path_mode="COPY",embed_textures=True)
print("Rebuilt 3 fitted hairstyles",sum(len(obj.data.polygons) for obj in objects),"triangles")
