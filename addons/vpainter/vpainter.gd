@tool
extends EditorPlugin

var debug_show_collider:bool = false
var vcamera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
var distance_to_camera
var ui_sidebar
var ui_activate_button
var brush_cursor

var edit_mode:bool:
	set(value):
		edit_mode = value
		if edit_mode:
			_set_collision()
		else:
			ui_sidebar.hide()
			_delete_collision()
var paint_color:Color

enum {MIX, ADD, SUBTRACT, MULTIPLY, DIVIDE}
var blend_mode = MIX
var blend_mode_stored:bool = false
var stored_blend_mode

enum {STANDART, INFLATE, MOVE, SMOOTH}
var sculpt_mode = STANDART

var current_tool = "_paint_tool"

var invert_brush:bool = false



var pressure_opacity:bool = false
var pressure_size:bool = false
var brush_pressure:float = 0.0
var process_drawing:bool = false

var brush_size:float = 1.0
var calculated_size:float = 1.0

var brush_opacity:float = 1.0
var calculated_opacity:float = 0.0

var brush_hardness:float = 1.0
var brush_spacing:float = 0.1

var current_mesh:MeshInstance3D
var data:MeshDataTool = MeshDataTool.new()
var undo_action:MeshDataTool = MeshDataTool.new()
var undo_tool:MeshDataTool = MeshDataTool.new()
var is_undo_action_set:bool = false
var undo_redo
var undone:bool
var undoable:bool = true
var editable_object:bool = false

var raycast_hit:bool = false
var hit_position
var hit_normal
var hit_target

func _ready() -> void:
	pass

func _handles(obj) -> bool:
	return editable_object


func _forward_3d_gui_input(camera, event) -> int:
	if !edit_mode:
		return 0
	_display_brush()
	_calculate_brush_pressure(event)
	_raycast(camera, event)


	if raycast_hit:
		return int(_user_input(event)) #the returned value blocks or unblocks the default input from godot
	else:
		return 0

func _user_input(event) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			process_drawing = true
			_process_drawing()
			return true
		else:
			process_drawing = false
			is_undo_action_set = false
			_set_collision()
			return false

	if event is InputEventKey:
		if event.is_pressed() and event.keycode == KEY_CTRL:
			if !blend_mode_stored:
				stored_blend_mode = blend_mode
				blend_mode_stored = true
			invert_brush = true
			blend_mode = SUBTRACT
			ui_sidebar.blend_modes.select(blend_mode)
			return false
		
		if event.is_released() and event.keycode == KEY_CTRL:
			invert_brush = false
			blend_mode = stored_blend_mode
			ui_sidebar.blend_modes.select(blend_mode)
			blend_mode_stored = false
			return false

		else:
			return false	
	else:
		#
		return false

func _undo_last_tool():
	current_mesh.mesh.clear_surfaces()
	undo_tool.commit_to_surface(current_mesh.mesh, 0)
	undoable = true
	ui_sidebar.undo_tool_button.disabled = true

func _undo_last_action():
	if !undone:
		current_mesh.mesh.clear_surfaces()
		undo_action.commit_to_surface(current_mesh.mesh, 0)
		undone = true
		ui_sidebar.undo_action_button.disabled = true

func _process_drawing():
	while process_drawing:
		call(current_tool)
		await get_tree().create_timer(brush_spacing).timeout

func _align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func _display_brush() -> void:
	if raycast_hit:
		brush_cursor.visible = true
		brush_cursor.position = hit_position
		brush_cursor.global_transform = _align_with_y(brush_cursor.global_transform, hit_normal + Vector3(0.0, 0.001, 0.0))
		distance_to_camera = (vcamera.global_position - brush_cursor.get_node(brush_cursor.size_mesh_dir).global_position).length()
		brush_cursor.get_node(brush_cursor.size_mesh_dir).mesh.top_radius = calculated_size/2.0
		brush_cursor.get_node(brush_cursor.size_mesh_dir).mesh.bottom_radius = calculated_size/2.0 + 0.03 * (distance_to_camera / 5)
		brush_cursor.get_node(brush_cursor.hardness_mesh_dir).mesh.top_radius = brush_cursor.get_node(brush_cursor.size_mesh_dir).mesh.top_radius * brush_hardness + 0.03 * (distance_to_camera / 5)
		brush_cursor.get_node(brush_cursor.hardness_mesh_dir).mesh.bottom_radius = brush_cursor.get_node(brush_cursor.size_mesh_dir).mesh.bottom_radius * brush_hardness
	else:
		brush_cursor.visible = false

func _calculate_brush_pressure(event) -> void:
	if event is InputEventMouseMotion:
		brush_pressure = event.pressure
		if pressure_size:
			calculated_size = (brush_size * brush_pressure)/2
		else:
			calculated_size = brush_size

		if pressure_opacity:
			calculated_opacity = brush_opacity * brush_pressure
		else:
			calculated_opacity = brush_opacity

func _raycast(camera:Node, event:InputEvent) -> void:
	if event is InputEventMouse:
		#RAYCAST FROM CAMERA:
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)
		var ray_distance = camera.far

		var space_state =  get_viewport().world_3d.direct_space_state
		var p = PhysicsRayQueryParameters3D.new()
		p.from = ray_origin
		p.to = ray_origin + ray_dir * ray_distance
		p.collision_mask = 524288
		var hit = space_state.intersect_ray(p)#ray_origin, ray_origin + ray_dir * ray_distance, [] , 524288 , true, false)
		#IF RAYCAST HITS A DRAWABLE SURFACE:
		if hit.size() == 0:
			raycast_hit = false
			return
		if hit:
			raycast_hit = true
			hit_position = hit.position
			hit_normal = hit.normal

func _paint_tool() -> void:
	data.create_from_surface(current_mesh.mesh, 0)
	
	if !is_undo_action_set: #Allows to store mesh data only ones per stroke, instead of every frame. 
		undo_action.create_from_surface(current_mesh.mesh, 0)
		is_undo_action_set = true
		undone = false
		ui_sidebar.undo_action_button.disabled = false
		
	if undoable: #Set in vpainter_ui.gd. Selecting a tool enables storing mesh data
		undo_tool.create_from_surface(current_mesh.mesh, 0)
		ui_sidebar.undo_tool_button.disabled = false
		undoable = false
		
	for i in range(data.get_vertex_count()):
		var vertex = current_mesh.to_global(data.get_vertex(i))
		var vertex_distance:float = vertex.distance_to(hit_position)

		if vertex_distance < calculated_size/2:
			var linear_distance = 1 - (vertex_distance / (calculated_size/2))
			var calculated_hardness = linear_distance * brush_hardness
			match blend_mode:
				MIX:
					data.set_vertex_color(i, data.get_vertex_color(i).lerp(paint_color, calculated_opacity * calculated_hardness))
				ADD:
					data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) + paint_color, calculated_opacity * calculated_hardness))
				SUBTRACT:
					data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) - paint_color, calculated_opacity * calculated_hardness))
				MULTIPLY:
					data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) * paint_color, calculated_opacity * calculated_hardness))
				DIVIDE:
					data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) / paint_color, calculated_opacity * calculated_hardness))
	
	current_mesh.mesh.clear_surfaces()
	data.commit_to_surface(current_mesh.mesh, 0)

func _displace_tool() -> void:
	data.create_from_surface(current_mesh.mesh, 0)
	
	if !is_undo_action_set: #Allows to store mesh data only ones per stroke, instead of every frame.
		undo_action.create_from_surface(current_mesh.mesh, 0)
		is_undo_action_set = true
		undone = false
		ui_sidebar.undo_action_button.disabled = false
		
	if undoable: #Set in vpainter_ui.gd. Selecting a tool enables storing mesh data
		undo_tool.create_from_surface(current_mesh.mesh, 0)
		ui_sidebar.undo_tool_button.disabled = false
		undoable = false
		
	for i in range(data.get_vertex_count()):
		var vertex = current_mesh.to_global(data.get_vertex(i))
		var vertex_distance:float = vertex.distance_to(hit_position)

		if vertex_distance < calculated_size/2:
			var linear_distance = 1 - (vertex_distance / (calculated_size/2))
			var calculated_hardness = linear_distance * brush_hardness

			if !invert_brush:
				data.set_vertex(i, data.get_vertex(i) + hit_normal * calculated_opacity * calculated_hardness)
			else:
				data.set_vertex(i, data.get_vertex(i) - hit_normal * calculated_opacity * calculated_hardness)
	
	current_mesh.mesh.clear_surfaces()
	data.commit_to_surface(current_mesh.mesh, 0)
		

func _fill_tool() -> void:
	data.create_from_surface(current_mesh.mesh, 0)
	
	if !is_undo_action_set: #Allows to store mesh data only ones per stroke, instead of every frame.
		undo_action.create_from_surface(current_mesh.mesh, 0)
		is_undo_action_set = true
		undone = false
		ui_sidebar.undo_action_button.disabled = false
		
	if undoable: #Set in vpainter_ui.gd. Selecting a tool enables storing mesh data
		undo_tool.create_from_surface(current_mesh.mesh, 0)
		ui_sidebar.undo_tool_button.disabled = false
		undoable = false
		
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		
		match blend_mode:
			MIX:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(paint_color, brush_opacity))
			ADD:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) + paint_color, brush_opacity))
			SUBTRACT:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) - paint_color, brush_opacity))
			MULTIPLY:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) * paint_color, brush_opacity))
			DIVIDE:
				data.set_vertex_color(i, data.get_vertex_color(i).lerp(data.get_vertex_color(i) / paint_color, brush_opacity))

	current_mesh.mesh.clear_surfaces()
	data.commit_to_surface(current_mesh.mesh, 0)
	process_drawing = false

func _sample_tool() -> void:
	data.create_from_surface(current_mesh.mesh, 0)
	
	var closest_distance:float = INF
	var closest_vertex_index:int

	for i in range(data.get_vertex_count()):
		var vertex = current_mesh.to_global(data.get_vertex(i))

		if vertex.distance_to(hit_position) < closest_distance:
			closest_distance = vertex.distance_to(hit_position)
			closest_vertex_index = i
	
	var picked_color = data.get_vertex_color(closest_vertex_index)
	paint_color = Color(picked_color.r, picked_color.g, picked_color.b, picked_color.a)
	ui_sidebar._set_paint_color(paint_color)


func _set_collision() -> void:
	var temp_collision = current_mesh.get_node_or_null(str(current_mesh.name) + "_col")
	if (temp_collision == null):
		current_mesh.create_trimesh_collision()
		temp_collision = current_mesh.get_node(str(current_mesh.name) + "_col")
		temp_collision.set_collision_layer(524288)
		temp_collision.set_collision_mask(524288)
	else:
		temp_collision.free()
		current_mesh.create_trimesh_collision()
		temp_collision = current_mesh.get_node(str(current_mesh.name) + "_col")
		temp_collision.set_collision_layer(524288)
		temp_collision.set_collision_mask(524288)
	
	if !debug_show_collider:
		temp_collision.hide()

func _delete_collision() -> void:
	if !is_instance_valid(current_mesh):return
	var temp_collision = current_mesh.get_node_or_null(str(current_mesh.name) + "_col")
	if (temp_collision != null):
		temp_collision.free()

func _set_edit_mode(value) -> void:
	edit_mode = value
	if !current_mesh:
		return
		if (!current_mesh.mesh):
			return

	if edit_mode:
		_set_collision()
	else:
		ui_sidebar.hide()
		_delete_collision()

func _make_local_copy() -> void:
	current_mesh.mesh = current_mesh.mesh.duplicate(false)

func _selection_changed() -> void:
	ui_sidebar.undo_tool_button.disabled = true
	#ui_activate_button._set_ui_sidebar(false)
	ui_sidebar.undo_action_button.disabled = true
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	if selection.size() == 1 and selection[0] is MeshInstance3D:
		current_mesh = selection[0]
		if current_mesh.mesh == null:
			ui_activate_button._set_ui_sidebar(false)
			ui_activate_button._hide()
			editable_object = false
		else:
			ui_activate_button._show()
			editable_object = true
	else:
		editable_object = false
		ui_activate_button._set_ui_sidebar(false) #HIDE THE SIDEBAR
		ui_activate_button._hide()

func _enter_tree():
	#SETUP THE SIDEBAR:
	ui_sidebar = load("res://addons/vpainter/vpainter_ui.tscn").instantiate()
	ui_sidebar.hide()
	ui_sidebar.vpainter = self
	ui_sidebar.undo_redo_manager = get_undo_redo()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar)
	#SETUP THE EDITOR BUTTON:
	ui_activate_button = load("res://addons/vpainter/vpainter_activate_button.tscn").instantiate()
	ui_activate_button.hide()
	ui_activate_button.vpainter = self
	ui_activate_button.ui_sidebar = ui_sidebar
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, ui_activate_button)
	#SELECTION SIGNAL:
	get_editor_interface().get_selection().connect("selection_changed", self._selection_changed)
	#LOAD BRUSH:
	brush_cursor = preload("res://addons/vpainter/res/brush_cursor/BrushCursor.tscn").instantiate()
	brush_cursor.visible = false
	add_child(brush_cursor)

func _exit_tree() -> void:
	#REMOVE THE SIDEBAR:
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, ui_sidebar)
	if ui_sidebar:
		ui_sidebar.queue_free()
	#REMOVE THE EDITOR BUTTON:
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, ui_activate_button)
	if ui_activate_button:
		ui_activate_button.queue_free()
	remove_child(brush_cursor)
