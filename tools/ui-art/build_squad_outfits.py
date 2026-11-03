import bpy
import bmesh
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/interface/customization/v3"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system = "NONE"
bpy.context.preferences.filepaths.save_version = 0
COLORS = dict(zip(["ink","shadow","navy","blue","ivory","white","brass","gold","leather","tan","wine","red","pants","gray","cream","steel"],
    ["141B28","0C111B","263650","40577A","E6DDC3","F3EDE1","B18A47","D8B966","6F4A2C","A07A42","793241","A64753","333A48","838B93","C3B78E","515B68"]))
materials = {}
for name, code in COLORS.items():
    material = bpy.data.materials.new(name)
    material.diffuse_color = tuple(int(code[i:i+2],16)/255 for i in (0,2,4))+(1,)
    materials[name] = material
palette = bpy.data.images.new("squad-palette-v3",width=16,height=16,alpha=True)
codes = list(COLORS.values())
def linear(v):
    return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
palette.pixels = [channel for y in range(16) for x in range(16) for channel in
    [*[linear(int(codes[(y//4)*4+x//4][i:i+2],16)/255) for i in (0,2,4)],1]]
palette.filepath_raw = str(OUT/"squad-palette-v3.png")
palette.file_format = "PNG"
palette.save()
palette.pack()
atlas = bpy.data.materials.new("SquadPalette")
atlas.use_nodes = True
texture = atlas.node_tree.nodes.new("ShaderNodeTexImage")
texture.image = palette
texture.interpolation = "Closest"
atlas.node_tree.links.new(texture.outputs["Color"],atlas.node_tree.nodes.get("Principled BSDF").inputs["Base Color"])
groups = {}
segment = "Torso"
asset_id = ""

def register(obj, color, fitted=False):
    obj.data.materials.append(materials[color])
    obj["fitted"] = fitted
    groups.setdefault((asset_id,segment),[]).append(obj)
    return obj

def box(center,size,color,bevel=.018,fitted=False):
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        modifier = obj.modifiers.new("Tailored edge","BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return register(obj,color,fitted)

def panel(points,color,thickness=.035,fitted=False):
    data = bpy.data.meshes.new("Cloth panel")
    data.from_pydata(points,[],[tuple(range(len(points)))])
    data.update()
    obj = bpy.data.objects.new("Cloth panel",data)
    bpy.context.scene.collection.objects.link(obj)
    register(obj,color,fitted)
    if thickness:
        bpy.context.view_layer.objects.active = obj
        mod = obj.modifiers.new("Cloth thickness","SOLIDIFY")
        mod.thickness = thickness
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def line(a,b,color,width=.045):
    a,b = Vector(a),Vector(b)
    obj = box((a+b)/2,(width,width,(b-a).length+width/2),color,.008)
    obj.rotation_euler = (b-a).to_track_quat("Z","Y").to_euler()
    return obj

def border(points,color,width=.045):
    for a,b in zip(points,points[1:]):
        line(a,b,color,width)

def badge(cx,y,cz,size,bull):
    def shape(coords,color,depth=0):
        panel([(cx+x*size,y-depth,cz+z*size) for x,z in coords],color,.008)
    if bull:
        shape([(-.30,.35),(-.60,.37),(-.81,.64),(-.78,.15),(-.47,-.01),(-.28,.09),(-.25,-.45),(0,-.67),(.25,-.45),(.28,.09),(.47,-.01),(.78,.15),(.81,.64),(.60,.37),(.30,.35),(0,.16)],"gold")
        shape([(-.19,.13),(0,.04),(.19,.13),(.15,-.33),(0,-.48),(-.15,-.33)],"ink",.012)
        shape([(-.22,-.02),(-.08,-.11),(-.18,-.17)],"gold",.018)
        shape([(.22,-.02),(.08,-.11),(.18,-.17)],"gold",.018)
        shape([(-.09,-.33),(0,-.29),(.09,-.33),(0,-.42)],"gold",.018)
    else:
        shape([(-.55,.58),(.55,.58),(.46,-.24),(0,-.66),(-.46,-.24)],"gold")
        shape([(-.43,.44),(.43,.44),(.36,-.17),(0,-.49),(-.36,-.17)],"ivory",.012)
        for i in range(8):
            angle=i*math.pi/4
            a=(math.cos(angle)*.18,math.sin(angle)*.18+.16)
            b=(math.cos(angle)*.35,math.sin(angle)*.35+.16)
            line((cx+a[0]*size,y-.026,cz+a[1]*size),(cx+b[0]*size,y-.026,cz+b[1]*size),"gold",.024)
        shape([(-.15,.02),(-.15,.22),(.15,.22),(.15,.02)],"gold",.027)
        shape([(-.26,-.28),(-.26,-.10),(-.12,-.10),(-.12,-.02),(.12,-.02),(.12,-.10),(.26,-.10),(.26,-.28)],"brass",.028)

for dawn in (False,True):
    for female in (False,True):
        asset_id = ("outfit-forest-initiate" if dawn else "outfit-ink-knight")+("-female-v1" if female else "-v1")
        segment = "Torso"
        box((0,0,3),(2.065,1.075,1.94),"wine" if dawn else "white",.035,True)
        if dawn:
            for side in (-1,1):
                panel([(side*.65,-.57,3.95),(side*1.04,-.56,3.88),(side*1.03,-.60,2.08),(side*.69,-.62,1.94)],"white",fitted=True)
                line((side*.63,-.61,3.9),(side*.64,-.66,2.03),"gold",.04)
                for z in (3.65,3.30,2.95,2.18):
                    box((side*.47,-.607,z),(.065,.05,.065),"gold",.014)
            line((0,-.577,3.95),(0,-.60,2.02),"gold",.04)
            box((0,-.59,3.49),(.105,.06,.24),"blue",.03)
            border([(-.40,-.61,3.90),(0,-.64,3.53),(.40,-.61,3.90)],"gold",.025)
            panel([(-1.12,.59,4.06),(1.12,.59,4.06),(1.30,.93,.66),(.82,1.02,.39),(-.82,1.02,.39),(-1.30,.93,.66)],"ivory",.05)
            for side in (-1,1):
                panel([(side*1.1,.57,4.05),(side*1.28,.76,3.5),(side*1.42,.98,.39),(side*.94,1.055,.25),(side*.79,.98,2.5)],"navy",.04)
                border([(side*1.12,.58,4.02),(side*1.30,.80,2.15),(side*1.42,.98,.39)],"gold",.038)
            panel([(-1.12,-.60,4.05),(-.18,-.69,3.92),(-.44,-.75,3.60),(-1.14,-.74,3.27)],"navy")
            panel([(.18,-.69,3.92),(1.12,-.60,4.05),(1.19,-.72,3.23),(.69,-.78,3.44)],"ivory")
            border([(-1.14,-.77,3.27),(-.44,-.78,3.60),(-.18,-.73,3.92)],"gold",.043)
            badge(-.76,-.78,3.66,.34,False)
            for side in (-1,1):
                for i in range(5):
                    box((side*(.24+i*.14),-.25+i*.09,4.08+(.05 if i%2 else 0)),(.25,.38,.19),"blue",.065)
            line((-.69,-.82,3.80),(.87,-.83,2.59),"tan",.13)
        else:
            for side in (-1,1):
                panel([(side*.30,-.57,3.88),(side*.91,-.58,3.91),(side*1.04,-.60,2.31),(side*.46,-.66,2.34)],"navy",fitted=True)
                line((side*.30,-.61,3.88),(side*.46,-.70,2.36),"brass",.04)
            panel([(-1.06,.59,4.02),(1.06,.59,4.02),(1.22,.79,2.98),(.45,.85,2.78),(-.43,.85,2.91),(-1.21,.76,3.07)],"ink",.05)
            border([(-1.21,.80,3.07),(-.43,.89,2.91),(.45,.89,2.78),(1.22,.83,2.98)],"gold",.052)
            panel([(.07,-.66,4.00),(1.08,-.60,4.04),(1.20,-.79,3.05),(.19,-.84,2.96)],"ink",.06)
            border([(.07,-.71,4.00),(.19,-.89,2.96),(1.20,-.84,3.05)],"gold",.055)
            panel([(-1.09,-.60,4.04),(-.08,-.66,4.00),(-.22,-.77,3.67),(-1.13,-.75,3.29)],"ink",.06)
            border([(-1.13,-.80,3.29),(-.22,-.82,3.67),(-.08,-.71,4.00)],"gold",.05)
            badge(.63,-.86,3.56,.45,True)
            badge(0,.91,3.43,.50,True)
            for side in (-1,1):
                box((side*.40,-.17,4.00),(.24,.66,.27),"ink",.04)
                line((side*.28,-.51,4.10),(side*.50,-.48,4.07),"gold",.05)
            box((0,-.75,3.96),(.15,.10,.15),"gold",.045)
        box((0,-.017,2.40),(2.13,1.14,.25 if dawn else .33),"leather",.03,True)
        box((0,-.636,2.40),(.43,.09,.28),"gold",.04)
        box((0,-.69,2.40),(.29,.025,.16),"leather",.018)
        line((-.03,-.71,2.39),(.21,-.71,2.39),"gold",.034)
        for x in (-.79,-.60,.60,.79):
            box((x,-.616,2.40),(.045,.045,.045),"gold",.008)
        for side,label in [(-1,"Left"),(1,"Right")]:
            segment = label+" Arm"
            x = side*1.5
            box((x,0,3.45 if dawn else 3.36),(1.045,1.06,1.16 if dawn else 1.31),"white" if dawn else "navy",.034)
            box((x,0,2.76 if dawn else 2.66),(1.07,1.08,.15),"gold" if dawn else "ivory",.022)
            if dawn:
                box((x,0,2.55),(1.04,1.05,.22),"red",.02)
                box((x,0,2.38),(1.07,1.08,.10),"gold",.017)
            else:
                box((x,0,2.17),(1.04,1.04,.25),"ink",.025)
                line((x-.4,-.54,2.17),(x+.4,-.54,2.17),"brass",.035)
            shoulder = "navy" if dawn and side<0 else ("ivory" if dawn else "ink")
            panel([(x-.54,-.57,4.04),(x+.54,-.57,4.04),(x+.59,-.70,3.40),(x-.58,-.70,3.43)],shoulder,.045)
            border([(x-.58,-.74,3.43),(x+.59,-.74,3.40)],"gold",.048)
            box((x,.03,4.02),(1.09,1.17,.15),shoulder,.03)
            segment = label+" Leg"
            x = side*.5
            box((x,0,1.27),(1.015,1.04,1.47),"white" if dawn else "pants",.025)
            panel([(x-.37,-.54,1.93),(x-.24,-.58,1.66),(x+.36,-.54,1.76)],"ivory" if dawn else "navy",.014)
            box((x,-.025,.53),(1.055,1.115,1.04),"ink" if dawn else "leather",.045)
            box((x,-.08,.14),(1.09,1.25,.25),"shadow",.035)
            panel([(x-.45,-.59,1.07),(x+.45,-.59,1.07),(x+.36,-.63,.83),(x+.12,-.64,.73),(x-.24,-.63,.85)],"gold" if dawn else "tan",.025)
            line((x-.43,-.60,.21),(x-.43,-.59,.91),"brass",.028)
            box((x,-.605,.49),(.56,.055,.105),"leather" if dawn else "tan",.012)
            box((x+.24,-.65,.49),(.13,.03,.14),"gold",.014)
        if female:
            for obj in groups[(asset_id,"Torso")]:
                if obj.get("fitted"):
                    bpy.context.view_layer.update()
                    inverse = obj.matrix_world.inverted()
                    bm = bmesh.new()
                    bm.from_mesh(obj.data)
                    for vertex in bm.verts:
                        vertex.co = obj.matrix_world @ vertex.co
                    for height in (2.45,2.8,3.2,3.65):
                        bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,
                            plane_co=(0,0,height),plane_no=(0,0,1))
                    for vertex in bm.verts:
                        vertex.co = inverse @ vertex.co
                    bm.to_mesh(obj.data)
                    bm.free()
                    for vertex in obj.data.vertices:
                        p = obj.matrix_world @ vertex.co
                        factor = max(.74,min(1,.74+abs(p.z-2.85)*.37))
                        p.x *= factor
                        vertex.co = inverse @ p

centers={"Torso":(0,0,3),"Left Arm":(-1.5,0,3),"Right Arm":(1.5,0,3),"Left Leg":(-.5,0,1),"Right Leg":(.5,0,1)}
fittings = {}
completed = []
for (identifier,body),parts in groups.items():
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = identifier+"__"+body.replace(" ","_")
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    uv = obj.data.uv_layers.active or obj.data.uv_layers.new(name="Palette")
    for face in obj.data.polygons:
        color = obj.data.materials[face.material_index].name
        index = list(COLORS).index(color)
        for loop in face.loop_indices:
            uv.data[loop].uv = ((index%4+.5)/4,(index//4+.5)/4)
        face.material_index=0
    obj.data.materials.clear()
    obj.data.materials.append(atlas)
    bm=bmesh.new();bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data);bm.free()
    bpy.context.view_layer.update()
    points=[obj.matrix_world@v.co for v in obj.data.vertices]
    low=Vector([min(v[i] for v in points) for i in range(3)])
    high=Vector([max(v[i] for v in points) for i in range(3)])
    center=(low+high)/2-Vector(centers[body])
    fittings.setdefault(identifier,{"category":"Outfit","parts":[]})["parts"].append({"segment":body,
        "size":[high.x-low.x,high.z-low.z,high.y-low.y],"offset":[center.x,center.z,center.y],
        "referenceSize":[2,2,1] if body=="Torso" else [1,2,1]})
    completed.append(obj)
(OUT/"fitting.json").write_text(json.dumps(fittings,indent=2),encoding="utf-8")
(OUT/"palette.json").write_text(json.dumps(COLORS,indent=2),encoding="utf-8")
bpy.ops.object.select_all(action="DESELECT")
for obj in completed:
    obj.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"clover-squad-outfits-v3.blend"))
bpy.ops.export_scene.fbx(filepath=str(OUT/"clover-squad-outfits-v3.fbx"),use_selection=True,object_types={"MESH"},
    axis_forward="-Z",axis_up="Y",global_scale=1,apply_unit_scale=False,bake_anim=False,
    use_mesh_modifiers=True,mesh_smooth_type="OFF",path_mode="COPY",embed_textures=True)
print("Built squad outfits:",len(completed),"parts;",sum(len(o.data.polygons) for o in completed),"triangles")
