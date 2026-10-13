class_name SurvivalBook
extends Node3D
signal notification_requested(message: String)
const Content = preload("res://scripts/book_content.gd")
const Geometry = preload("res://scripts/book_geometry.gd")
var content = Content.new()
var geometry = Geometry.new()
var spread = 0
var is_open = false
var is_busy = false
var is_zoomed = false
var camera: Camera3D
func _ready():
	add_child(geometry)
	content.notification_requested.connect(notification_requested.emit)
	_update_visible_spread()
const BOOK_UP = Vector3(0, -0.02, -0.46)
const BOOK_DOWN = Vector3(0, -0.75, -0.4)
func initialize_book(target_camera: Camera3D):
	camera = target_camera
	position = BOOK_DOWN
	rotation_degrees.x = -12
	visible = false
	camera.add_child(self)

func _update_page_labels(labels: Dictionary, index: int):
	var data = content.get_page_content(index)
	labels.chap.text = data[0]
	labels.title.text = data[1]
	labels.body.text = data[2]
	labels.foot.text = data[3]

func _update_visible_spread():
	_update_page_labels(geometry.left_labels, spread * 2 - 1)
	_update_page_labels(geometry.right_labels, spread * 2)

func _animate_cover_rotation(opening: bool):
	var tween = create_tween()
	var target = -180.0 if opening else 0.0
	tween.tween_property(geometry.cover, "rotation_degrees:y", target, 0.6).set_trans(Tween.TRANS_SINE)
	await tween.finished

func toggle_open_state():
	if is_busy: return
	is_busy = true
	if not is_open:
		is_open = true
		_update_visible_spread()
		visible = true
		position = BOOK_DOWN
		geometry.cover.rotation_degrees.y = 0
		var lift = create_tween()
		lift.tween_property(self, "position", BOOK_UP, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await lift.finished
		await _animate_cover_rotation(true)
		geometry._set_page_content_visible(true)
		_update_visible_spread()
	else:
		geometry.leaf.visible = false
		await _animate_cover_rotation(false)
		var lower = create_tween()
		lower.tween_property(self, "position", BOOK_DOWN, 0.35).set_trans(Tween.TRANS_CUBIC)
		await lower.finished
		visible = false
		is_open = false
	is_busy = false

func turn_page(direction: int):
	if is_busy or not is_open: return
	var target_spread = spread + direction
	if target_spread < 0 or target_spread * 2 >= content.pages.size(): return
	is_busy = true
	geometry.leaf.visible = true
	if direction > 0:
		_update_page_labels(geometry.leaf_front, spread * 2)
		_update_page_labels(geometry.leaf_back, target_spread * 2 - 1)
		# Trang phải mới nằm dưới tờ đang lật.
		_update_page_labels(geometry.right_labels, target_spread * 2)
		geometry.leaf.rotation_degrees.y = 0
	else:
		_update_page_labels(geometry.leaf_front, target_spread * 2)
		_update_page_labels(geometry.leaf_back, spread * 2 - 1)
		# Trang trái mới được lộ ra khi lật ngược.
		_update_page_labels(geometry.left_labels, target_spread * 2 - 1)
		geometry.leaf.rotation_degrees.y = -180
	var tween = create_tween()
	tween.tween_property(geometry.leaf, "rotation_degrees:y", -180.0 if direction > 0 else 0.0, 0.55).set_trans(Tween.TRANS_SINE)
	await tween.finished
	spread = target_spread
	geometry.leaf.visible = false
	_update_visible_spread()
	is_busy = false

func set_reading_zoom(zoomed: bool):
	is_zoomed = zoomed and is_open
	if not camera: return
	var target_position = Vector3(0, 0.02, -0.32) if is_zoomed else (BOOK_UP if is_open else BOOK_DOWN)
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(camera, "fov", 58.0 if is_zoomed else 75.0, 0.22)

func refresh_visible_pages():
	if is_open and not is_busy: _update_visible_spread()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and is_open:
		if not is_busy:
			set_reading_zoom(event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			toggle_open_state()
			get_viewport().set_input_as_handled()
		elif is_open:
			match event.keycode:
				KEY_ESCAPE: toggle_open_state()
				KEY_E, KEY_RIGHT: turn_page(1)
				KEY_Q, KEY_LEFT: turn_page(-1)
			get_viewport().set_input_as_handled()

func get_reading_hint() -> String:
	return "Q / ←  trang trước    E / →  trang sau    J  đóng sổ"

func record_discovery(id: String, inventory: Dictionary):
	content.record_discovery(id, inventory)
	refresh_visible_pages()

func record_travel_distance(distance: float):
	content.record_travel_distance(distance)
	refresh_visible_pages()
