@tool
extends MeshInstance3D

@export var size_mesh_dir:NodePath
var size_mesh:MeshInstance3D

@export var hardness_mesh_dir:NodePath
var hardness_mesh:MeshInstance3D

func _enter_tree() -> void:
	size_mesh = get_node(size_mesh_dir)
	hardness_mesh = get_node(hardness_mesh_dir)
	
	
