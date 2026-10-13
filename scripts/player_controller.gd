extends CharacterBody3D
signal interaction_requested
var head
var cam
var pitch = 0.0
var controls_locked = false
func _ready():
	position = Vector3(0, 1.0, 0)
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	add_child(col)
	head = Node3D.new()
	head.position = Vector3(0, 0.7, 0)
	add_child(head)
	cam = Camera3D.new()
	cam.fov = 75
	cam.near = 0.02
	cam.current = true
	head.add_child(cam)

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not controls_locked:
		rotate_y(-event.relative.x * 0.0025)
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.4, 1.4)
		head.rotation.x = pitch

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_E: interaction_requested.emit()

func _physics_process(delta):
	var dir = Vector3.ZERO
	if not controls_locked:
		var inp = Vector2.ZERO
		if Input.is_key_pressed(KEY_W): inp.y -= 1
		if Input.is_key_pressed(KEY_S): inp.y += 1
		if Input.is_key_pressed(KEY_A): inp.x -= 1
		if Input.is_key_pressed(KEY_D): inp.x += 1
		var b = global_transform.basis
		dir = (b.x * inp.x + b.z * inp.y).normalized()
	var speed = 8.0 if Input.is_key_pressed(KEY_SHIFT) else 5.0
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if is_on_floor():
		velocity.y = 0.0
		if Input.is_key_pressed(KEY_SPACE) and not controls_locked:
			velocity.y = 6.0
	else:
		velocity.y -= 20.0 * delta
	move_and_slide()

