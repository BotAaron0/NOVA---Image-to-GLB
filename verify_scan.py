import sys
from pathlib import Path

import bpy


path = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
bpy.ops.wm.read_factory_settings(use_empty=True)
assert bpy.ops.wm.obj_import(filepath=str(path)) == {"FINISHED"}
meshes = [obj.data for obj in bpy.context.scene.objects if obj.type == "MESH"]
assert meshes and all(mesh.uv_layers for mesh in meshes)
textures = {
    node.image
    for mesh in meshes
    for material in mesh.materials
    if material and material.node_tree
    for node in material.node_tree.nodes
    if node.type == "TEX_IMAGE" and node.image
}
assert textures and all(image.size[0] and image.has_data for image in textures)
print("Verified mesh faces:", sum(len(mesh.polygons) for mesh in meshes))
print("Verified photo textures:", [tuple(image.size) for image in textures])
