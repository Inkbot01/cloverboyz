import bpy
import bmesh
import math
import json
import shutil
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "assets/interface/customization/v1"
EXPORT = DEST / "exports"
EXPORT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system = "NONE"
bpy.context.preferences.filepaths.save_version = 0

COLORS = {
    "ink": "1D2421", "shadow": "111715", "cloth": "343D34",
    "forest": "3B5742", "sage": "6B8060", "brass": "AA8749",
    "gold": "D2B577", "ivory": "E1D9BC", "silver": "B8BCAD",
    "silver_dark": "737E77", "leather": "554335", "leather_light": "81634A",
    "auburn": "754634", "auburn_light": "AF7652", "skin": "B78D68",
    "steel": "65746D"
}
MATS = {}
def linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

for name, value in COLORS.items():
    rgb = tuple(linear(int(value[i:i+2], 16) / 255) for i in (0, 2, 4))
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*rgb, 1)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*rgb, 1)
    shader.inputs["Roughness"].default_value = 0.86
    MATS[name] = material

palette = bpy.data.images.new("clover-palette-v1", width=16, height=16, alpha=True)
pixels = []
keys = list(COLORS)
for y in range(16):
    for x in range(16):
        code = COLORS[keys[(y // 4) * 4 + x // 4]]
        pixels.extend([linear(int(code[i:i+2], 16) / 255) for i in (0, 2, 4)] + [1])
palette.pixels = pixels
palette.filepath_raw = str(EXPORT / "clover-palette-v1.png")
palette.file_format = "PNG"
palette.save()
palette.pack()
atlas = bpy.data.materials.new("CloverPalette")
atlas.use_nodes = True
node = atlas.node_tree.nodes.new("ShaderNodeTexImage")
node.image = palette
node.interpolation = "Closest"
shader = atlas.node_tree.nodes.get("Principled BSDF")
atlas.node_tree.links.new(node.outputs["Color"], shader.inputs["Base Color"])
shader.inputs["Roughness"].default_value = 0.86

assets = []
active = None
def asset(identifier, category, attachment, anchor):
    global active
    collection = bpy.data.collections.new(identifier)
    bpy.context.scene.collection.children.link(collection)
    active = {"id": identifier, "category": category, "attachment": attachment,
              "anchor": anchor, "collection": collection, "objects": []}
    assets.append(active)

def register(obj, name, material):
    obj.name = name
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)
    active["collection"].objects.link(obj)
    obj.data.materials.append(MATS[material])
    active["objects"].append(obj)
    return obj

def box(name, center, size, material, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    register(obj, name, material)
    if bevel:
        mod = obj.modifiers.new("Cut corners", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def mesh(name, vertices, faces, material):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    active["collection"].objects.link(obj)
    data.materials.append(MATS[material])
    active["objects"].append(obj)
    return obj

def lock(name, centers, widths, depths, material):
    vertices = []
    for (x, y, z), w, d in zip(centers, widths, depths):
        vertices.extend([(x-w,y-d,z), (x+w,y-d,z), (x+w,y+d,z), (x-w,y+d,z)])
    faces = [(3,2,1,0)]
    for i in range(len(centers)-1):
        a, b = i*4, (i+1)*4
        faces.extend([(a+j,a+(j+1)%4,b+(j+1)%4,b+j) for j in range(4)])
    n = len(vertices)
    faces.append((n-4,n-3,n-2,n-1))
    return mesh(name, vertices, faces, material)

def cap(material):
    vertices = []
    segments = 12
    rings = [(4.57,1.06,.61),(4.95,1.08,.63),(5.16,.90,.55),(5.28,.35,.27)]
    for z, rx, ry in rings:
        for i in range(segments):
            angle = 2*math.pi*i/segments
            c, s = math.cos(angle), math.sin(angle)
            vertices.append((rx*math.copysign(math.sqrt(abs(c)),c),ry*math.copysign(math.sqrt(abs(s)),s),z))
    faces = [tuple(reversed(range(segments)))]
    for j in range(len(rings)-1):
        for i in range(segments):
            a=j*segments+i
            b=j*segments+(i+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces.append(tuple(range(36,48)))
    obj=mesh("Scalp",vertices,faces,material)
    return obj

def stripe(name, points, width, material):
    return lock(name,points,[width]*len(points),[.018]*len(points),material)

def clover(x,y,z,scale,material):
    shape = [(-1,0),(-3,1),(-3,3),(-1,3),(0,1),(1,3),(3,3),(3,1),
             (1,0),(3,-1),(3,-3),(1,-3),(0,-1),(-1,-3),(-3,-3),(-3,-1)]
    points=[(x+a*scale,y,z+b*scale) for a,b in shape]
    return mesh("Clover crest",points,[tuple(range(len(points)))],material)

asset("hair-iron-spikes-v1","Hair","HairAttachment",(0,0,4.5))
cap("silver_dark")
for i,(x,tip,h,w) in enumerate([(-.87,-1.20,.45,.23),(-.58,-.83,.72,.26),
    (-.25,-.38,.89,.28),(.12,.20,.98,.28),(.46,.66,.76,.29),(.78,1.12,.52,.24)]):
    lock("Crown spike",[(x,0,4.98),(x*.95,-.015,5.24),(tip,-.02,5.05+h)],
         [w,w*.80,.018],[.36,.27,.015],"ivory" if i%2 else "silver")
for x,z,dx in [(-.85,4.32,-.10),(-.50,4.49,.04),(-.10,4.38,.12),(.30,4.57,.13),(.69,4.39,.10)]:
    lock("Angular fringe",[(x,-.39,5.07),(x,-.64,4.81),(x+dx,-.65,z)],
         [.25,.22,.015],[.15,.12,.015],"silver")
for side in (-1,1):
    lock("Temple lock",[(side*.92,.03,4.91),(side*1.11,.02,4.65),(side*1.06,-.02,4.25)],
         [.18,.16,.02],[.37,.31,.015],"silver_dark")

asset("hair-wind-swept-v1","Hair","HairAttachment",(0,0,4.5))
cap("shadow")
for x,y,h in [(-.77,.12,.19),(-.39,.18,.28),(.0,.19,.33),(.4,.16,.27),(.78,.12,.13)]:
    lock("Swept crown",[(x,y,4.98),(x+.15,-.03,5.30+h),(x+.64,-.16,5.35+h)],
         [.30,.30,.02],[.38,.25,.01],"ink")
for x,z in [(-.80,4.38),(-.48,4.26),(-.12,4.42),(.26,4.57),(.64,4.61)]:
    lock("Side swept fringe",[(x-.18,-.37,5.10),(x,-.62,4.82),(x+.24,-.68,z)],
         [.30,.27,.016],[.16,.13,.012],"ink")
lock("Nape",[(0,.43,4.85),(0,.53,4.55),(.13,.58,4.25)],[.77,.65,.47],[.12,.12,.06],"shadow")
for side in (-1,1):
    lock("Sideburn",[(side*.98,-.02,4.85),(side*1.04,-.04,4.49),(side*.96,-.15,4.16)],
         [.15,.13,.025],[.29,.24,.015],"ink")

asset("hair-ember-ponytail-v1","Hair","HairAttachment",(0,0,4.5))
cap("auburn")
for side in (-1,1):
    lock("Curtain fringe",[(side*.19,-.44,5.13),(side*.63,-.63,4.90),(side*.96,-.60,4.26)],
         [.26,.27,.065],[.15,.13,.03],"auburn_light")
    lock("Framing lock",[(side*.87,-.01,4.94),(side*1.08,-.07,4.46),(side*.95,-.10,4.00)],
         [.21,.16,.018],[.37,.25,.018],"auburn")
box("Ponytail clasp",(0,.62,4.91),(.48,.19,.30),"brass",.035)
for x,depth in [(-.22,.04),(.05,.14),(.29,.01)]:
    lock("Ponytail ribbon",[(x,.60,4.95),(x,.96,4.69),(x+.08,1.03+depth,4.04),(x-.04,.86,3.38)],
         [.25,.29,.22,.025],[.20,.22,.18,.02],"auburn_light" if x<0 else "auburn")

def outfit(identifier, forest=False):
    asset(identifier,"Outfit","Segmented R6 body pieces",(0,0,0))
    base="forest" if forest else "ink"
    trim="sage" if forest else "brass"
    box("Torso__tunic",(0,0,3.02),(2.08,1.075,1.91),base,.05)
    box("Torso__undershirt",(0,-.555,3.38),(.53,.055,1.10),"ivory",.015)
    for side in (-1,1):
        lapel=box("Torso__lapel",(side*.39,-.606,3.48),(.16,.075,1.06),trim,.022)
        lapel.rotation_euler.y=side*-.17
        box("Torso__seam",(side*.81,-.551,2.94),(.035,.03,1.35),"cloth")
    box("Torso__waistband",(0,-.012,2.42),(2.13,1.12,.21),"leather",.025)
    box("Torso__buckle",(0,-.605,2.42),(.32,.07,.27),"gold",.025)
    box("Torso__buckle_inset",(0,-.649,2.42),(.19,.02,.14),"shadow")
    crest = clover(.63,-.587,3.55,.047,trim)
    crest.name = "Torso__clover"
    for side,label in [(-1,"Left"),(1,"Right")]:
        x=side*1.51
        box(label+" Arm__sleeve",(x,0,3.49),(1.045,1.065,1.055),base,.04)
        box(label+" Arm__cuff",(x,0,2.99),(1.067,1.087,.14),trim,.02)
        box(label+" Arm__bracer",(x,0,2.33),(1.035,1.045,.53),"leather",.05)
        box(label+" Arm__bracer_strap",(x,-.535,2.37),(1.02,.04,.09),"leather_light")
        x=side*.5
        box(label+" Leg__trousers",(x,0,1.24),(1.025,1.045,1.53),"cloth" if forest else "shadow",.025)
        box(label+" Leg__boot",(x,-.03,.41),(1.065,1.145,.81),"leather" if forest else "ink",.055)
        box(label+" Leg__sole",(x,-.06,.08),(1.105,1.205,.15),"shadow",.025)
        box(label+" Leg__boot_top",(x,-.035,.79),(1.08,1.16,.13),trim,.015)
        box(label+" Leg__knee_panel",(x,-.552,1.13),(.59,.05,.40),"leather_light" if forest else "steel",.035)
    if forest:
        for side in (-1,1):
            flap=box("Torso__short_tabard",(side*.58,-.579,2.17),(.72,.08,.47),base,.035)
            flap.rotation_euler.y=side*.05
            box("Torso__tabard_hem",(side*.58,-.626,1.965),(.68,.025,.06),trim)

outfit("outfit-ink-knight-v1")
outfit("outfit-forest-initiate-v1",True)

asset("accessory-clover-headband-v1","Accessory","HatAttachment",(0,0,4.5))
for name,center,size in [
    ("Forehead",(0,-.765,4.79),(2.03,.075,.22)),
    ("Back",(0,.56,4.79),(2.03,.075,.22)),
    ("Left",(-1.035,-.027,4.79),(.075,1.175,.22)),
    ("Right",(1.035,-.027,4.79),(.075,1.175,.22))]:
    box(name,center,size,"ink",.018)
clover(.54,-.817,4.79,.026,"gold")
lock("Headband tail",[(1.00,.49,4.82),(1.20,.64,4.48),(1.29,.72,4.11)],
     [.11,.13,.09],[.04,.04,.025],"ink")

asset("accessory-black-mantle-v1","Accessory","BodyBackAttachment",(0,0,3))
vertices=[(-.95,.30,3.97),(.95,.30,3.97),(1.17,.70,3.56),(.91,.84,2.33),
          (.44,.89,2.19),(0,.91,2.29),(-.44,.89,2.19),(-.91,.84,2.33),(-1.17,.70,3.56)]
obj=mesh("Mantle",vertices,[(0,1,2,3,4,5,6,7,8)],"ink")
bpy.context.view_layer.objects.active=obj
obj.select_set(True)
mod=obj.modifiers.new("Cloth thickness","SOLIDIFY")
mod.thickness=.055
bpy.ops.object.modifier_apply(modifier=mod.name)
for a,b in [(2,3),(3,4),(4,5),(5,6),(6,7),(7,8)]:
    p,q=Vector(vertices[a]),Vector(vertices[b])
    direction=q-p
    center=(p+q)/2
    trim=box("Mantle brass hem",center,(.055,.065,direction.length+.025),"brass")
    trim.rotation_euler=direction.to_track_quat("Z","Y").to_euler()
for x in (-.62,.62):
    box("Collar",(x,.16,3.96),(.59,.60,.17),"brass",.03)
    box("Collar cloth",(x,.15,4.015),(.52,.55,.15),"ink",.03)

asset("accessory-grimoire-satchel-v1","Accessory","WaistCenterAttachment",(0,0,2))
box("Pages",(1.14,-.02,2.40),(.57,.39,.78),"ivory",.02)
box("Front cover",(1.14,-.253,2.40),(.66,.09,.86),"forest",.027)
box("Back cover",(1.14,.211,2.40),(.66,.09,.86),"forest",.027)
box("Spine",(.835,-.025,2.40),(.095,.48,.86),"leather",.03)
for z in (2.06,2.74):
    box("Cover edge",(1.14,-.305,z),(.54,.025,.045),"brass")
clover(1.14,-.31,2.41,.034,"gold")
box("Book clasp",(1.44,-.03,2.40),(.14,.49,.13),"brass",.015)
strap=box("Satchel belt loop",(1.10,.10,2.88),(.18,.11,.36),"leather",.02)

def finish_meshes(record):
    grouped={}
    for obj in record["objects"]:
        key=obj.name.split("__")[0] if record["category"]=="Outfit" else record["id"]
        grouped.setdefault(key,[]).append(obj)
    completed=[]
    for name,objects in grouped.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
        obj=bpy.context.object
        obj.name=name
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        while obj.data.uv_layers:
            obj.data.uv_layers.remove(obj.data.uv_layers[0])
        uv=obj.data.uv_layers.new(name="Palette")
        uv.active_render = True
        for face in obj.data.polygons:
            material=obj.data.materials[face.material_index]
            index=keys.index(material.name)
            coord=((index%4+.5)/4,(index//4+.5)/4)
            for loop in face.loop_indices:
                uv.data[loop].uv=coord
        obj.data.materials.clear()
        obj.data.materials.append(atlas)
        for face in obj.data.polygons:
            face.material_index=0
            face.use_smooth=False
        modifier=obj.modifiers.new("Export triangulation","TRIANGULATE")
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(obj.data)
        bm.free()
        obj["body_segment"] = name if record["category"] == "Outfit" else ""
        completed.append(obj)
    record["objects"]=completed

for record in assets:
    finish_meshes(record)

for record in assets:
    if record["id"] == "accessory-grimoire-satchel-v1":
        for obj in record["objects"]:
            obj.location.x -= .24
            obj.location.y -= .70

for record in list(assets):
    if record["category"] == "Hair" or record["id"] == "accessory-clover-headband-v1":
        for obj in record["objects"]:
            for vertex in obj.data.vertices:
                world = obj.matrix_world @ vertex.co
                world.x *= .70
                vertex.co = obj.matrix_world.inverted() @ world
    if record["category"] != "Outfit":
        continue
    record["fit"] = "male-straight"
    asset(record["id"].replace("-v1", "-female-v1"), "Outfit", record["attachment"], record["anchor"])
    active["fit"] = "female-tapered"
    for original in record["objects"]:
        obj = original.copy()
        obj.data = original.data.copy()
        active["collection"].objects.link(obj)
        active["objects"].append(obj)
        if original.get("body_segment") == "Torso":
            levels = [(1.90, 1.0), (2.05, 1.0), (2.75, .73), (3.10, .77), (3.65, 1.0), (4.05, 1.0)]
            bm = bmesh.new()
            bm.from_mesh(obj.data)
            for vertex in bm.verts:
                vertex.co = obj.matrix_world @ vertex.co
            for height in (2.05, 2.75, 3.10, 3.65):
                bmesh.ops.bisect_plane(bm, geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
                    dist=.00001, plane_co=(0,0,height), plane_no=(0,0,1))
            bmesh.ops.triangulate(bm, faces=list(bm.faces))
            inverse = obj.matrix_world.inverted()
            for vertex in bm.verts:
                vertex.co = inverse @ vertex.co
            bm.to_mesh(obj.data)
            bm.free()
            for vertex in obj.data.vertices:
                world = obj.matrix_world @ vertex.co
                factor = 1.0
                for (low, a), (high, b) in zip(levels, levels[1:]):
                    if low <= world.z <= high:
                        factor = a + (b-a) * (world.z-low) / (high-low)
                        break
                world.x *= factor
                vertex.co = obj.matrix_world.inverted() @ world

for record in assets:
    for obj in record["objects"]:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm, faces=list(bm.faces))
        collapsed = [face for face in bm.faces if face.calc_area() <= 1e-10]
        if collapsed:
            bmesh.ops.delete(bm, geom=collapsed, context="FACES_ONLY")
        bm.to_mesh(obj.data)
        bm.free()

manifest={
    "version":1,
    "status":"local-source-assets-not-uploaded",
    "style":"faceted low-poly pixel fantasy; ink, olive charcoal, parchment and brass",
    "rig":"Approximate custom Male/Female silhouettes from user Studio screenshot, October 4 2026. No source rig was available for exact fitting.",
    "coordinates":{"source":"Blender Z-up, front -Y","unit":"1 source unit = 1 intended Roblox stud",
        "bodyCenters":{"Head":[0,0,4.5],"Torso":[0,0,3],"Left Arm":[-1.5,0,3],
                       "Right Arm":[1.5,0,3],"Left Leg":[-.5,0,1],"Right Leg":[.5,0,1]},
        "referenceHeight":5,"referenceHeadDimensions":[1.4,1,1],
        "femaleTorsoWidthScaleByHeight":[[2.05,1],[2.75,.73],[3.10,.77],[3.65,1]],
        "measurements":"Illustrative source-unit estimates from screenshot, not measured Studio dimensions"},
    "palette":{"file":"exports/clover-palette-v1.png","size":[16,16],
        "filter":"nearest","uv":"constant texel per polygon","colors":COLORS,
        "atlasRectangles":{name:[(i%4)*4,(3-i//4)*4,4,4] for i,name in enumerate(keys)},
        "sliceMargins":None},
    "assets":[],
    "limitations":["No cloud asset IDs or runtime catalog changes.",
        "Rigid segmented game cosmetics, not skinned or caged Marketplace layered clothing.",
        "Fit and attachment offsets require Studio import inspection and pose testing.",
        "Hair intersects scalp intentionally; interlocking strands form separate closed shells.",
        "Body segment names assume six-piece rigs; confirm names and offsets on the custom rigs.",
        "Blender contact sheet is an offline geometry preview, not a Roblox engine screenshot."],
    "references":["https://create.roblox.com/docs/art/modeling",
        "https://create.roblox.com/docs/art/accessories/creating-rigid/importing",
        "https://create.roblox.com/docs/avatar/rigid-accessories"]
}
for record in assets:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in record["objects"]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=record["objects"][0]
    stem=EXPORT/record["id"]
    bpy.ops.export_scene.gltf(filepath=str(stem)+".gltf",export_format="GLTF_SEPARATE",
        use_selection=True,export_yup=True,export_apply=True,export_animations=False,
        export_materials="EXPORT",export_image_format="AUTO")
    bpy.ops.export_scene.fbx(filepath=str(stem)+".fbx",use_selection=True,
        object_types={"MESH"},axis_forward="-Z",axis_up="Y",global_scale=1,
        apply_unit_scale=False,bake_anim=False,use_mesh_modifiers=True,
        mesh_smooth_type="OFF",path_mode="COPY",embed_textures=True)
    bounds=[obj.matrix_world@Vector(corner) for obj in record["objects"] for corner in obj.bound_box]
    entry={"id":record["id"],"category":record["category"],"suggestedAttachment":record["attachment"],
        "fit":record.get("fit", "shared-head-and-limbs"),
        "sourceAnchor":record["anchor"],"gltf":"exports/"+record["id"]+".gltf",
        "fbx":"exports/"+record["id"]+".fbx",
        "triangles":sum(len(o.data.polygons) for o in record["objects"]),
        "bounds":{"min":[min(v[i] for v in bounds) for i in range(3)],
                  "max":[max(v[i] for v in bounds) for i in range(3)]},
        "parts":[{"name":o.name,"bodySegment":o.get("body_segment"),"triangles":len(o.data.polygons)} for o in record["objects"]],
        "robloxAssetId":None}
    manifest["assets"].append(entry)
    record["collection"].hide_render=True
    record["collection"].hide_viewport=True

face_original=DEST/"face-determined-emerald-v1-source.png"
face_target=EXPORT/"face-determined-emerald-v1.png"
if face_original.exists():
    shutil.copy2(face_original,face_target)
    loaded=bpy.data.images.load(str(face_target),check_existing=True)
    manifest["face"]={"id":"face-determined-emerald-v1","file":"exports/"+face_target.name,
        "source":"OpenAI built-in image_gen","size":list(loaded.size),"channels":loaded.channels,
        "robloxAssetId":None,"status":"generated alpha texture; head fit unverified"}
    loaded.pack()

preview=bpy.data.collections.new("PREVIEW_ONLY")
bpy.context.scene.collection.children.link(preview)
active={"collection":preview,"objects":[]}
def preview_copy(record,offset):
    for original in record["objects"]:
        obj=original.copy()
        obj.data=original.data
        preview.objects.link(obj)
        obj.location.x+=offset

looks=[
    (-6.3,["hair-iron-spikes-v1","outfit-ink-knight-v1","accessory-clover-headband-v1","accessory-black-mantle-v1"]),
    (-2.1,["hair-wind-swept-v1","outfit-forest-initiate-v1","accessory-grimoire-satchel-v1"]),
    (2.1,["hair-ember-ponytail-v1","outfit-ink-knight-female-v1","accessory-grimoire-satchel-v1"]),
    (6.3,["hair-wind-swept-v1","outfit-forest-initiate-female-v1","accessory-black-mantle-v1"])
]
for offset,ids in looks:
    for record in assets:
        if record["id"] in ids:
            preview_copy(record,offset)
    box("Preview head",(offset,0,4.5),(1.4,1,1),"skin",.075)
    for x in (-1.5,1.5):
        box("Preview hand",(offset+x,0,2.08),(.98,.98,.21),"skin",.035)
        box("Preview forearm",(offset+x,0,2.75),(.98,.98,.54),"skin",.025)
    if face_target.exists():
        material=bpy.data.materials.get("Preview face")
        if material is None:
            material=bpy.data.materials.new("Preview face")
            material.use_nodes=True
            shader=material.node_tree.nodes.get("Principled BSDF")
            image_node=material.node_tree.nodes.new("ShaderNodeTexImage")
            image_node.image=loaded
            image_node.interpolation="Closest"
            material.node_tree.links.new(image_node.outputs["Color"],shader.inputs["Base Color"])
            material.node_tree.links.new(image_node.outputs["Alpha"],shader.inputs["Alpha"])
            shader.inputs["Roughness"].default_value=1
            material.surface_render_method="DITHERED"
        face=mesh("Preview face",[(offset-.7,-.506,4),(offset+.7,-.506,4),(offset+.7,-.506,5),(offset-.7,-.506,5)],[(0,1,2,3)],"skin")
        face.data.materials.clear()
        face.data.materials.append(material)
        uv=face.data.uv_layers.new()
        for i,coord in enumerate([(0,0),(1,0),(1,1),(0,1)]):
            uv.data[i].uv=coord

box("Display floor",(0,0,-.17),(200,200,.2),"shadow")
scene=bpy.context.scene
scene.render.engine="CYCLES"
scene.cycles.samples=32
scene.cycles.use_denoising=True
scene.render.resolution_x=1800
scene.render.resolution_y=900
scene.render.resolution_percentage=100
scene.world.color=(.14,.14,.14)
scene.view_settings.view_transform="Standard"

def aim(obj,point):
    obj.rotation_euler=(Vector(point)-obj.location).to_track_quat("-Z","Y").to_euler()

bpy.ops.object.camera_add(location=(7,-30,11))
camera=bpy.context.object
camera.name="Offline preview camera"
aim(camera,(0,0,2.75))
camera.data.type="ORTHO"
camera.data.ortho_scale=19.4
scene.camera=camera
for location,energy,size in [((0,-10,13),1800,9),((-8,-3,7),1100,8),((4,6,11),2400,7)]:
    bpy.ops.object.light_add(type="AREA",location=location)
    light=bpy.context.object
    light.data.energy=energy
    light.data.shape="DISK"
    light.data.size=size
    aim(light,(0,0,3))

bpy.ops.wm.save_as_mainfile(filepath=str(DEST/"clover-customization-v1.blend"))
scene.render.filepath=str(DEST/"preview-front-v1.png")
bpy.ops.render.render(write_still=True)
camera.location=(7,30,11)
aim(camera,(0,0,2.75))
scene.render.filepath=str(DEST/"preview-back-v1.png")
bpy.ops.render.render(write_still=True)

(EXPORT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
(DEST/"IMPORT.txt").write_text(
    "CLOVERBOYZ CHARACTER ASSET STARTER PACK V1\n\n"
    "3 hair styles, 2 outfit designs each with Male/Female torso fits, 3 accessories, 1 transparent face.\n"
    "Source: clover-customization-v1.blend. Rebuild with tools/ui-art/build_customization_assets.py in Blender 4.4 background mode.\n"
    "Each asset collection contains editable geometry. PREVIEW_ONLY contains display mannequins and is excluded from exports.\n\n"
    "IMPORT\n"
    "Use Studio Home > Import and choose one exports/*.gltf (keep adjacent .bin and .png files together), or the matching embedded-texture .fbx.\n"
    "Fit is estimated from the user's custom Male/Female Studio screenshot, not measured from a source rig.\n"
    "Keep hierarchy and inspect scale. The source mannequin is 5 units tall, torso 2 x 1 x 2, head 1.4 x 1 x 1.\n"
    "Female torso variants taper to 73 percent width at the waist. Adjust to the actual mesh before release.\n"
    "Exports retain shared mannequin coordinates. They do not include attachment objects or welds.\n"
    "Use the suggested attachment and source anchor in exports/manifest.json as fitting references.\n"
    "Hair and small accessories require fitting to the intended head or body attachment in Studio.\n"
    "Outfits contain five rigid pieces named by body segment. Fit each to its corresponding custom limb/torso, with collision disabled and Massless enabled.\n"
    "Check left/right limb assignments against your actual rig before attachment; preview coordinates are documented in the manifest.\n"
    "The short tabard and mantle are rigid game cosmetics. These are not skinned/caged Marketplace layered clothing.\n"
    "The face PNG has transparent surroundings and belongs on a classic head front decal. Upload and inspect transparency and alignment before catalog integration.\n\n"
    "VERIFICATION\n"
    "Blender source/export generation and front/back geometry previews are local checks only.\n"
    "No Studio import, attachment, motion, moderation or in-engine texture check has been performed.\n"
    "No cloud IDs were invented and no live catalog/save changes were made.\n"
    "Keep the existing nine-image interface upload pipeline unchanged; it does not publish this mesh pack.\n",
    encoding="utf-8")
print("CUSTOMIZATION_ASSETS_COMPLETE "+json.dumps({"assets":len(assets),"triangles":sum(x["triangles"] for x in manifest["assets"]),"path":str(DEST)}))
