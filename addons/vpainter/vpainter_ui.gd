@tool
extends Control

var vpainter
var color_channel = Color(0.0, 0.0, 0.0, 1.0)
var vcamera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
var distance_to_camera
var undo_redo_manager : EditorUndoRedoManager

#LOCAL COPY BUTTON
@export var local_copy_button_path:NodePath
var local_copy_button:Button

#UNDO LAST BUTTON
@export var undo_last_button_path:NodePath
var undo_last_button:Button

#COLOR PICKER:
@export var color_picker_dir:NodePath
var color_picker:ColorPickerButton

#PEN PRESSURE:
@export var pen_pressure_settings_dir:NodePath
var pen_pressure_settings:VBoxContainer
@export var button_opacity_pressure_dir:NodePath
var button_opacity_pressure:CheckBox
@export var button_size_pressure_dir:NodePath
var button_size_pressure:CheckBox

#TOOLS:
@export var button_paint_dir:NodePath
var button_paint:Button

@export var button_sample_dir:NodePath
var button_sample:Button

@export var button_displace_dir:NodePath
var button_displace:Button

@export var button_fill_dir:NodePath
var button_fill:Button

#COLOR CHANNELS:
@export var channel_white_dir:NodePath
var channel_white:CheckBox

@export var channel_red_dir:NodePath
var channel_red:CheckBox

@export var channel_green_dir:NodePath
var channel_green:CheckBox

@export var channel_blue_dir:NodePath
var channel_blue:CheckBox

@export var channel_alpha_dir:NodePath
var channel_alpha:CheckBox

#BRUSH SLIDERS:
@export var brush_size_slider_dir:NodePath
var brush_size_slider:HSlider

@export var brush_size_spinbox_dir:NodePath
var brush_size_spinbox:SpinBox

@export var brush_opacity_slider_dir:NodePath
var brush_opacity_slider:HSlider

@export var brush_opacity_spinbox_dir:NodePath
var brush_opacity_spinbox:SpinBox

@export var brush_hardness_slider_dir:NodePath
var brush_hardness_slider:HSlider

@export var brush_hardness_spinbox_dir:NodePath
var brush_hardness_spinbox:SpinBox

@export var brush_spacing_slider_dir:NodePath
var brush_spacing_slider:HSlider

@export var brush_spacing_spinbox_dir:NodePath
var brush_spacing_spinbox:SpinBox

#BLENDING MODES:
@export var blend_modes_path:NodePath
var blend_modes:OptionButton

func _enter_tree():
	local_copy_button = get_node(local_copy_button_path)
	local_copy_button.button_down.connect(_make_local_copy)
	
	undo_last_button = get_node(undo_last_button_path)
	undo_last_button.button_down.connect(_undo_last)
	
	color_picker = get_node(color_picker_dir)
	color_picker.connect("color_changed", self._set_paint_color)	
	
	pen_pressure_settings = get_node(pen_pressure_settings_dir)
	channel_red = get_node(channel_red_dir)
	channel_red.connect("toggled", self._channel_red_toggle)
	channel_white = get_node(channel_white_dir)
	channel_white.connect("toggled", self._channel_white_toggle)
	channel_green = get_node(channel_green_dir)
	channel_green.connect("toggled", self._channel_green_toggle)
	channel_blue = get_node(channel_blue_dir)
	channel_blue.connect("toggled", self._channel_blue_toggle)
	channel_alpha = get_node(channel_alpha_dir)
	channel_alpha.connect("toggled", self._channel_alpha_toggle)
	button_opacity_pressure = get_node(button_opacity_pressure_dir)
	button_opacity_pressure.connect("toggled", self._set_opacity_pressure)
	button_size_pressure = get_node(button_size_pressure_dir)
	button_size_pressure.connect("toggled", self._set_size_pressure)
	
	button_paint = get_node(button_paint_dir)
	button_paint.connect("toggled", self._set_paint_tool)
	
	button_sample = get_node(button_sample_dir)
	button_sample.connect("toggled", self._set_sample_tool)
	
	button_displace = get_node(button_displace_dir)
	button_displace.connect("toggled", self._set_displace_tool)
	
	button_fill = get_node(button_fill_dir)
	button_fill.connect("toggled", self._set_fill_tool)

	brush_size_slider = get_node(brush_size_slider_dir)
	brush_size_slider.value_changed.connect(_set_brush_size)
	brush_size_spinbox = get_node(brush_size_spinbox_dir)
	brush_size_spinbox.connect("value_changed", self._set_brush_size)
	brush_opacity_slider = get_node(brush_opacity_slider_dir)
	brush_opacity_slider.connect("value_changed", self._set_brush_opacity)
	brush_opacity_spinbox = get_node(brush_opacity_spinbox_dir)
	brush_opacity_spinbox.connect("value_changed", self._set_brush_opacity)
	brush_hardness_slider = get_node(brush_hardness_slider_dir)
	brush_hardness_slider.connect("value_changed", self._set_brush_hardness)
	brush_hardness_spinbox = get_node(brush_hardness_spinbox_dir)
	brush_hardness_spinbox.connect("value_changed", self._set_brush_hardness)
	brush_spacing_slider = get_node(brush_spacing_slider_dir)
	brush_spacing_slider.connect("value_changed", self._set_brush_spacing)
	brush_spacing_spinbox = get_node(brush_spacing_spinbox_dir)
	brush_spacing_spinbox.connect("value_changed", self._set_brush_spacing)
	
	blend_modes = get_node(blend_modes_path)
	blend_modes.connect("item_selected", self._set_blend_mode)
	blend_modes.clear()
	blend_modes.add_item("MIX", 0)
	blend_modes.add_item("ADD", 1)
	blend_modes.add_item("SUBTRACT", 2)
	blend_modes.add_item("MULTIPLY", 3)
	blend_modes.add_item("DIVIDE", 4)

	button_paint.set_pressed(true)
	
func _exit_tree():
	local_copy_button = get_node(local_copy_button_path)
	local_copy_button.button_down.disconnect(_make_local_copy)
	undo_last_button = get_node(undo_last_button_path)
	undo_last_button.button_down.disconnect(_undo_last)
	color_picker = get_node(color_picker_dir)
	color_picker.disconnect("color_changed", self._set_paint_color)
	channel_white = get_node(channel_white_dir)
	channel_white.disconnect("toggled", self._channel_white_toggle)
	channel_red = get_node(channel_red_dir)
	channel_red.disconnect("toggled", self._channel_red_toggle)
	channel_green = get_node(channel_green_dir)
	channel_green.disconnect("toggled", self._channel_green_toggle)
	channel_blue = get_node(channel_blue_dir)
	channel_blue.disconnect("toggled", self._channel_blue_toggle)
	channel_alpha = get_node(channel_alpha_dir)
	channel_alpha.disconnect("toggled", self._channel_alpha_toggle)
	button_opacity_pressure = get_node(button_opacity_pressure_dir)
	button_opacity_pressure.disconnect("toggled", self._set_opacity_pressure)
	button_size_pressure = get_node(button_size_pressure_dir)
	button_size_pressure.disconnect("toggled", self._set_size_pressure)
	button_paint = get_node(button_paint_dir)
	button_paint.disconnect("toggled", self._set_paint_tool)
	button_sample = get_node(button_sample_dir)
	button_sample.disconnect("toggled", self._set_sample_tool)
	button_displace = get_node(button_displace_dir)
	button_displace.disconnect("toggled", self._set_displace_tool)
	button_fill = get_node(button_fill_dir)
	button_fill.disconnect("toggled", self._set_fill_tool)
	brush_size_slider = get_node(brush_size_slider_dir)
	brush_size_slider.value_changed.disconnect(_set_brush_size)
	brush_size_spinbox = get_node(brush_size_spinbox_dir)
	brush_size_spinbox.disconnect("value_changed", self._set_brush_size)
	brush_opacity_slider = get_node(brush_opacity_slider_dir)
	brush_opacity_slider.disconnect("value_changed", self._set_brush_opacity)
	brush_opacity_spinbox = get_node(brush_opacity_spinbox_dir)
	brush_opacity_spinbox.disconnect("value_changed", self._set_brush_opacity)
	brush_hardness_slider = get_node(brush_hardness_slider_dir)
	brush_hardness_slider.disconnect("value_changed", self._set_brush_hardness)
	brush_hardness_spinbox = get_node(brush_hardness_spinbox_dir)
	brush_hardness_spinbox.disconnect("value_changed", self._set_brush_hardness)
	brush_spacing_slider = get_node(brush_spacing_slider_dir)
	brush_spacing_slider.disconnect("value_changed", self._set_brush_spacing)
	brush_spacing_spinbox = get_node(brush_spacing_spinbox_dir)
	brush_spacing_spinbox.disconnect("value_changed", self._set_brush_spacing)
	blend_modes = get_node(blend_modes_path)
	blend_modes.disconnect("item_selected", self._set_blend_mode)

func _make_local_copy():
	vpainter._make_local_copy()

func _undo_last():
	vpainter._undo_last()


func _set_paint_color(value):
	channel_white.button_pressed = false
	channel_red.button_pressed = false
	channel_green.button_pressed = false
	channel_blue.button_pressed = false
	channel_alpha.button_pressed = false
	vpainter.paint_color = value
	color_picker.set_pick_color(value)
	
func _channel_white_toggle(value):
	if channel_white.button_pressed:
		channel_red.button_pressed = false
		channel_green.button_pressed = false
		channel_blue.button_pressed = false
		channel_alpha.button_pressed = false
		color_channel = Color("White")
	else:
		color_channel = Color("Black")
	vpainter.paint_color = color_channel
	color_picker.set_pick_color(color_channel)
	
func _channel_red_toggle(value):
	if channel_red.button_pressed:
		channel_white.button_pressed = false
		color_channel.r = 1.0
	else:
		color_channel.r = 0.0
	vpainter.paint_color = color_channel
	color_picker.set_pick_color(color_channel)
		
func _channel_green_toggle(value):
	if channel_green.button_pressed:
		channel_white.button_pressed = false
		color_channel.g = 1.0
	else:
		color_channel.g = 0.0
	vpainter.paint_color = color_channel
	color_picker.set_pick_color(color_channel)

func _channel_blue_toggle(value):
	if channel_blue.button_pressed:
		channel_white.button_pressed = false
		color_channel.b = 1.0
	else:
		color_channel.b = 0.0
	vpainter.paint_color = color_channel
	color_picker.set_pick_color(color_channel)
		
func _channel_alpha_toggle(value):
	if channel_alpha.button_pressed:
		channel_white.button_pressed = false
		color_channel.a = 1.0
	#else:
		#color_channel.a = 1.0
	vpainter.paint_color = color_channel
	color_picker.set_pick_color(color_channel)

func _set_blend_mode(id):
	#MIX, ADD, SUBTRACT, MULTIPLY, DIVIDE
	match id:
		0: #MIX
			vpainter.blend_mode = vpainter.MIX
		1: #ADD
			vpainter.blend_mode = vpainter.ADD
		2: #SUBTRACT
			vpainter.blend_mode = vpainter.SUBTRACT
		3: #MULTIPLY
			vpainter.blend_mode = vpainter.MULTIPLY
		4: #DIVIDE
			vpainter.blend_mode = vpainter.DIVIDE

func _input(event):
	if event is InputEventKey and event.pressed:

		if event.keycode == KEY_BRACKETLEFT:
			_set_brush_size(brush_size_slider.value - 0.05)
		if event.keycode == KEY_BRACKETRIGHT:
			_set_brush_size(brush_size_slider.value + 0.05)
		
		if event.keycode == KEY_APOSTROPHE :
			_set_brush_opacity(brush_opacity_slider.value - 0.01)
		if event.keycode == KEY_BACKSLASH :
			_set_brush_opacity(brush_opacity_slider.value + 0.01)

func _set_opacity_pressure(value):
	vpainter.pressure_opacity = value

func _set_size_pressure(value):
	vpainter.pressure_size = value

func _set_paint_tool(value):
	vpainter.brush_size = brush_size_slider.value
	if value:
		vpainter.current_tool = "_paint_tool"
		pen_pressure_settings.visible = true
		blend_modes.visible = true

		button_paint.set_pressed(true)
		button_sample.set_pressed(false)
		button_displace.set_pressed(false)
		button_fill.set_pressed(false)

func _set_sample_tool(value):
	if value:
		vpainter.current_tool = "_sample_tool"
		pen_pressure_settings.visible = false
		blend_modes.visible = false
		
		button_paint.set_pressed(false)
		button_sample.set_pressed(true)
		button_displace.set_pressed(false)
		button_fill.set_pressed(false)

func _set_blur_tool(value):
	if value:
		vpainter.current_tool = "_blur_tool"
		pen_pressure_settings.visible = false
		blend_modes.visible = false
		
		button_paint.set_pressed(false)
		button_sample.set_pressed(false)
		button_displace.set_pressed(false)
		button_fill.set_pressed(false)

func _set_displace_tool(value):
	if value:
		vpainter.current_tool = "_displace_tool"
		pen_pressure_settings.visible = true
		blend_modes.visible = false
		
		button_paint.set_pressed(false)
		button_sample.set_pressed(false)
		button_displace.set_pressed(true)
		button_fill.set_pressed(false)

func _set_fill_tool(value):
	if value:
		vpainter.current_tool = "_fill_tool"
		pen_pressure_settings.visible = false
		blend_modes.visible = true

		button_paint.set_pressed(false)
		button_sample.set_pressed(false)
		button_displace.set_pressed(false)
		button_fill.set_pressed(true)

func _set_brush_size(value):
	var camera:Node
	brush_size_slider.value = value
	brush_size_spinbox.value = brush_size_slider.value
	vpainter.brush_size = value
	distance_to_camera = (vcamera.global_position - vpainter.brush_cursor.get_child(0).global_position).length()
	
	vpainter.brush_cursor.get_node(vpainter.brush_cursor.size_mesh_dir).mesh.top_radius = value/2.0
	vpainter.brush_cursor.get_node(vpainter.brush_cursor.size_mesh_dir).mesh.bottom_radius = value/2.0 + 0.03 * (distance_to_camera / 5)
	_set_brush_hardness(brush_hardness_slider.value)

func _set_brush_opacity(value):
	brush_opacity_slider.value = value
	brush_opacity_spinbox.value = brush_opacity_slider.value
	vpainter.brush_opacity = value

func _set_brush_hardness(value):
	brush_hardness_slider.value = value
	brush_hardness_spinbox.value = brush_hardness_slider.value
	vpainter.brush_hardness = value
	vpainter.brush_cursor.get_node(vpainter.brush_cursor.hardness_mesh_dir).mesh.top_radius = vpainter.brush_cursor.get_node(vpainter.brush_cursor.size_mesh_dir).mesh.top_radius * value + 0.03 * (distance_to_camera / 5)
	vpainter.brush_cursor.get_node(vpainter.brush_cursor.hardness_mesh_dir).mesh.bottom_radius = vpainter.brush_cursor.get_node(vpainter.brush_cursor.size_mesh_dir).mesh.bottom_radius * value

func _set_brush_spacing(value):
	brush_spacing_slider.value = value
	brush_spacing_spinbox.value = brush_spacing_slider.value
	vpainter.brush_spacing = value
