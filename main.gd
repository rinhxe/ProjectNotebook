extends Node3D
# Survival Guidebook 3D - Godot 4.x
# WASD: di chuyển | Shift: chạy | Space: nhảy | Chuột: nhìn quanh
# E: nhặt / khám phá | J: mở-đóng sổ tay | Q/E hoặc ←/→: lật trang (khi đang mở sổ)
# Esc: nhả chuột (click để bắt lại)

const TABS = ["Vật phẩm", "Chế tạo", "Sinh tồn"]
const INK = Color("3b2a1a")
const BOOK_UP = Vector3(0, -0.02, -0.46)
const BOOK_DOWN = Vector3(0, -0.75, -0.4)

var entries = {
	"tips": {"tab": 2, "title": "Chào mừng, kẻ sống sót",
		"text": "Bạn bị lạc trên một hòn đảo hoang.\nHãy nhặt vật phẩm và khám phá. Mỗi phát hiện mới sẽ được ghi vào quyển sổ này."},
	"water_rule": {"tab": 2, "title": "Quy tắc số 3",
		"text": "3 phút không có không khí.\n3 ngày không có nước.\n3 tuần không có thức ăn.\n\nƯu tiên: nước, lửa, rồi thức ăn."},
	"compass": {"tab": 2, "title": "Đừng đi lạc",
		"text": "Mặt trời mọc ở phía Đông, lặn ở phía Tây.\nĐi xa nhà trại, hãy bẻ cành cây để đánh dấu đường quay về."},
	"wood": {"tab": 0, "title": "Gỗ",
		"text": "Cành khô nhặt dưới tán cây.\n\nDùng để nhóm lửa, làm cán rìu, dựng lều.\nGỗ ẩm sẽ cháy rất khói."},
	"stone": {"tab": 0, "title": "Đá",
		"text": "Đá sắc cạnh dùng được như lưỡi dao thô.\n\nDùng để làm rìu đá và đánh lửa."},
	"berry": {"tab": 0, "title": "Quả mọng đỏ",
		"text": "ĂN ĐƯỢC. Hồi +8 thức ăn.\n\nMọc thành chùm trên bụi thấp. Bẻ ra không có nhựa trắng thường là an toàn."},
	"mushroom": {"tab": 0, "title": "Nấm tím",
		"text": "ĐỘC!\n\nGây buồn nôn và mất nước nhanh.\nĐừng bao giờ ăn nấm khi chưa chắc chắn."},
	"water": {"tab": 0, "title": "Ao nước",
		"text": "Nước đọng chứa vi khuẩn.\n\nLuôn đun sôi ít nhất 1 phút trước khi uống."},
	"axe": {"tab": 1, "title": "Rìu đá",
		"text": "Công thức:\n1 Gỗ + 1 Đá\n\nChặt cây nhanh gấp 3 lần so với tay không."},
	"campfire": {"tab": 1, "title": "Lửa trại",
		"text": "Công thức:\n3 Gỗ\n\nGiữ ấm, nấu ăn, đun nước và xua thú dữ vào ban đêm."}
}
var pages = []
var unlocked = {"tips": true, "water_rule": true}
var inv = {}
var names = {"wood": "Gỗ", "stone": "Đá", "berry": "Quả mọng", "mushroom": "Nấm", "water": "Ao nước"}
var items = []
var target = -1

var player; var head; var cam
var book; var cover; var leaf
var left_l; var right_l; var leaf_front; var leaf_back
var book_open = false
var busy = false
var spread = 0
var new_page = -1
var pitch = 0.0
var hud; var hint; var toast

func _ready():
	pages = entries.keys()
	_build_world()
	_build_player()
	_build_book()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ---------------- Helpers ----------------
func _mi(parent, mesh, color, pos = Vector3.ZERO, unshaded = false):
	var m = MeshInstance3D.new()
	m.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m

func _box(x, y, z):
	var b = BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

func _cyl(top, bottom, h):
	var c = CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	return c

func _sphere(r, h):
	var s = SphereMesh.new()
	s.radius = r
	s.height = h
	return s

# ---------------- Thế giới ----------------
func _build_world():
	var rng = RandomNumberGenerator.new()
	rng.seed = 11
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.fog_enabled = true
	env.fog_light_color = Color("b7cbd6")
	env.fog_density = 0.012
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var ground = StaticBody3D.new()
	add_child(ground)
	var plane = PlaneMesh.new()
	plane.size = Vector2(240, 240)
	_mi(ground, plane, Color("3f7a3a"))
	var gcol = CollisionShape3D.new()
	var gshape = BoxShape3D.new()
	gshape.size = Vector3(240, 1, 240)
	gcol.shape = gshape
	gcol.position = Vector3(0, -0.5, 0)
	ground.add_child(gcol)

	for i in 90:
		var p = Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60))
		if p.length() < 7.0 or p.distance_to(Vector2(14, -12)) < 9.0:
			continue
		var t = StaticBody3D.new()
		t.position = Vector3(p.x, 0, p.y)
		add_child(t)
		var h = rng.randf_range(3.5, 5.5)
		_mi(t, _cyl(0.3, 0.4, h), Color("5a3a1e"), Vector3(0, h * 0.5, 0))
		_mi(t, _cyl(0.0, 2.0, 3.8), Color("1f5a2a"), Vector3(0, h + 1.2, 0))
		var tc = CollisionShape3D.new()
		var ts = CylinderShape3D.new()
		ts.radius = 0.45
		ts.height = h
		tc.shape = ts
		tc.position = Vector3(0, h * 0.5, 0)
		t.add_child(tc)

	_add_item("water", Vector3(14, 0, -12))
	_add_item("wood", Vector3(3, 0, -5))
	_add_item("wood", Vector3(-4, 0, -6))
	_add_item("stone", Vector3(5, 0, 3))
	_add_item("berry", Vector3(-6, 0, 4))
	_add_item("mushroom", Vector3(2, 0, 7))
	var kinds = ["wood", "wood", "wood", "stone", "stone", "berry", "berry", "mushroom", "mushroom", "mushroom"]
	for k in kinds:
		var q = Vector2(rng.randf_range(-45, 45), rng.randf_range(-45, 45))
		if q.length() < 8.0:
			q *= 2.0
		_add_item(k, Vector3(q.x, 0, q.y))

func _add_item(id, pos):
	var n = Node3D.new()
	n.position = pos
	add_child(n)
	var it = {"id": id, "node": n, "taken": false, "r": 0.0, "dot": 0.93}
	match id:
		"wood":
			var m = _mi(n, _cyl(0.06, 0.07, 0.9), Color("8b5a2b"), Vector3(0, 0.07, 0))
			m.rotation_degrees = Vector3(0, 30, 90)
		"stone":
			_mi(n, _sphere(0.24, 0.34), Color("8f9296"), Vector3(0, 0.15, 0))
		"berry":
			_mi(n, _sphere(0.45, 0.7), Color("2d6a2d"), Vector3(0, 0.35, 0))
			for a in 7:
				var ang = a * 0.9
				_mi(n, _sphere(0.06, 0.12), Color("d02030"), Vector3(cos(ang) * 0.38, 0.3 + (a % 3) * 0.12, sin(ang) * 0.38))
		"mushroom":
			_mi(n, _cyl(0.04, 0.05, 0.22), Color("e8e0cc"), Vector3(0, 0.11, 0))
			_mi(n, _sphere(0.14, 0.14), Color("a050d0"), Vector3(0, 0.24, 0))
		"water":
			_mi(n, _cyl(5.0, 5.0, 0.06), Color("3a7bd5"), Vector3(0, 0.03, 0))
			it.r = 5.0
			it.dot = 0.2
	items.append(it)

# ---------------- Người chơi ----------------
func _build_player():
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1.0, 0)
	add_child(player)
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	player.add_child(col)
	head = Node3D.new()
	head.position = Vector3(0, 0.7, 0)
	player.add_child(head)
	cam = Camera3D.new()
	cam.fov = 75
	cam.near = 0.02
	cam.current = true
	head.add_child(cam)

# ---------------- Quyển sách 3D ----------------
func _make_labels(parent, x, z, roty):
	var d = {}
	var defs = [["chap", 0.185, 26, Color("8a6a3a")], ["title", 0.135, 44, Color("7a1f1f")],
		["body", 0.0, 32, INK], ["foot", -0.185, 24, Color("8a6a3a")]]
	for df in defs:
		var l = Label3D.new()
		l.pixel_size = 0.0005
		l.font_size = df[2]
		l.modulate = df[3]
		l.width = 500.0
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		l.double_sided = false
		l.position = Vector3(x, df[1], z)
		l.rotation_degrees.y = roty
		parent.add_child(l)
		d[df[0]] = l
	return d

func _build_book():
	book = Node3D.new()
	book.position = BOOK_DOWN
	book.rotation_degrees = Vector3(-12, 0, 0)
	book.visible = false
	cam.add_child(book)
	var leather = Color("4a2e1a")
	var paper = Color("efe3c0")
	_mi(book, _box(0.64, 0.44, 0.012), leather, Vector3(0, 0, -0.052), true)
	_mi(book, _box(0.30, 0.40, 0.012), paper, Vector3(-0.155, 0, -0.03), true)
	_mi(book, _box(0.30, 0.40, 0.012), paper, Vector3(0.155, 0, -0.03), true)
	_mi(book, _box(0.012, 0.44, 0.07), Color("33200f"), Vector3(0, 0, -0.02), true)
	left_l = _make_labels(book, -0.155, -0.021, 0.0)
	right_l = _make_labels(book, 0.155, -0.021, 0.0)

	# Tờ giấy lật (2 mặt)
	leaf = Node3D.new()
	leaf.visible = false
	book.add_child(leaf)
	_mi(leaf, _box(0.30, 0.40, 0.004), Color("f6ecca"), Vector3(0.155, 0, -0.012), true)
	leaf_front = _make_labels(leaf, 0.155, -0.007, 0.0)
	leaf_back = _make_labels(leaf, 0.155, -0.017, 180.0)

	# Bìa trước (bản lề ở gáy sách)
	cover = Node3D.new()
	book.add_child(cover)
	_mi(cover, _box(0.31, 0.44, 0.012), leather, Vector3(0.155, 0, 0.04), true)
	_mi(cover, _box(0.20, 0.12, 0.002), Color("c9a24b"), Vector3(0.155, 0.06, 0.047), true)
	var t = Label3D.new()
	t.text = "SỔ TAY\nSINH TỒN"
	t.pixel_size = 0.0006
	t.font_size = 64
	t.modulate = Color("3b2a1a")
	t.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	t.double_sided = false
	t.position = Vector3(0.155, 0.06, 0.0495)
	cover.add_child(t)

func _page_data(p):
	if p >= pages.size():
		return ["", "", "", ""]
	var id = pages[p]
	if unlocked.has(id):
		return [TABS[entries[id].tab].to_upper(), entries[id].title, entries[id].text, "- %d -" % (p + 1)]
	return ["", "???", "Chưa khám phá.\nHãy đi tìm để ghi thêm trang này.", "- %d -" % (p + 1)]

func _set_page(L, p):
	var d = _page_data(p)
	L.chap.text = d[0]
	L.title.text = d[1]
	L.body.text = d[2]
	L.foot.text = d[3]

func _show_spread():
	_set_page(left_l, spread * 2)
	_set_page(right_l, spread * 2 + 1)

func _toggle_book():
	if busy:
		return
	busy = true
	if not book_open:
		book_open = true
		if new_page >= 0:
			spread = new_page / 2
			new_page = -1
		_show_spread()
		leaf.visible = false
		cover.rotation_degrees.y = 0
		book.position = BOOK_DOWN
		book.visible = true
		var tw = create_tween()
		tw.tween_property(book, "position", BOOK_UP, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(cover, "rotation_degrees:y", -180.0, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func(): busy = false)
	else:
		leaf.visible = false
		var tw2 = create_tween()
		tw2.tween_property(cover, "rotation_degrees:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		tw2.tween_property(book, "position", BOOK_DOWN, 0.35).set_trans(Tween.TRANS_CUBIC)
		tw2.tween_callback(func():
			book.visible = false
			book_open = false
			busy = false)

func _flip(dir):
	if busy or not book_open:
		return
	var tgt = spread + dir
	var n_spreads = (pages.size() + 1) / 2
	if tgt < 0 or tgt >= n_spreads:
		return
	busy = true
	leaf.visible = true
	var tw = create_tween()
	if dir > 0:
		leaf.rotation_degrees.y = 0
		_set_page(leaf_front, spread * 2 + 1)
		_set_page(leaf_back, tgt * 2)
		_set_page(right_l, tgt * 2 + 1)
		tw.tween_property(leaf, "rotation_degrees:y", -180.0, 0.55).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func():
			_set_page(left_l, tgt * 2)
			leaf.visible = false
			spread = tgt
			busy = false)
	else:
		leaf.rotation_degrees.y = -180
		_set_page(leaf_front, tgt * 2 + 1)
		_set_page(leaf_back, spread * 2)
		_set_page(left_l, tgt * 2)
		tw.tween_property(leaf, "rotation_degrees:y", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func():
			_set_page(right_l, tgt * 2 + 1)
			leaf.visible = false
			spread = tgt
			busy = false)

# ---------------- HUD ----------------
func _build_hud():
	var ui = CanvasLayer.new()
	add_child(ui)
	var dot = ColorRect.new()
	dot.color = Color(1, 1, 1, 0.8)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.offset_left = -2
	dot.offset_right = 2
	dot.offset_top = -2
	dot.offset_bottom = 2
	ui.add_child(dot)
	hud = Label.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 20)
	ui.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(16, 604)
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color("ffe9a8"))
	ui.add_child(hint)
	toast = Label.new()
	toast.position = Vector2(340, 70)
	toast.add_theme_font_size_override("font_size", 26)
	toast.add_theme_color_override("font_color", Color("ffe9a8"))
	toast.modulate.a = 0.0
	ui.add_child(toast)

func _notify(text):
	toast.text = text
	toast.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(toast, "modulate:a", 0.0, 0.6)

# ---------------- Gameplay ----------------
func _unlock(id):
	if unlocked.has(id):
		return
	unlocked[id] = true
	new_page = pages.find(id)
	_notify("Sổ tay đã ghi thêm: " + entries[id].title + "  (nhấn J)")
	if book_open and not busy:
		_show_spread()

func _interact():
	if target < 0:
		return
	var it = items[target]
	var id = it.id
	if id != "water":
		it.taken = true
		it.node.visible = false
		inv[id] = inv.get(id, 0) + 1
	_unlock(id)
	if inv.get("wood", 0) >= 1 and inv.get("stone", 0) >= 1:
		_unlock("axe")
	if inv.get("wood", 0) >= 3:
		_unlock("campfire")

func _find_target():
	target = -1
	var best = 9999.0
	var cp = cam.global_position
	var fwd = -cam.global_transform.basis.z
	for i in items.size():
		var it = items[i]
		if it.taken:
			continue
		var to = it.node.global_position + Vector3(0, 0.25, 0) - cp
		var d = to.length() - it.r
		if d > 3.5:
			continue
		var dt = fwd.dot(to.normalized())
		if dt < it.dot:
			continue
		var score = d - dt * 2.0
		if score < best:
			best = score
			target = i

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not book_open:
		player.rotate_y(-event.relative.x * 0.0025)
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.4, 1.4)
		head.rotation.x = pitch
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_J: _toggle_book()
			KEY_ESCAPE:
				if book_open:
					_toggle_book()
				else:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_E:
				if book_open:
					_flip(1)
				else:
					_interact()
			KEY_Q:
				if book_open: _flip(-1)
			KEY_RIGHT:
				if book_open: _flip(1)
			KEY_LEFT:
				if book_open: _flip(-1)

func _physics_process(delta):
	var dir = Vector3.ZERO
	if not book_open:
		var inp = Vector2.ZERO
		if Input.is_key_pressed(KEY_W): inp.y -= 1
		if Input.is_key_pressed(KEY_S): inp.y += 1
		if Input.is_key_pressed(KEY_A): inp.x -= 1
		if Input.is_key_pressed(KEY_D): inp.x += 1
		var b = player.global_transform.basis
		dir = (b.x * inp.x + b.z * inp.y).normalized()
	var speed = 8.0 if Input.is_key_pressed(KEY_SHIFT) else 5.0
	player.velocity.x = dir.x * speed
	player.velocity.z = dir.z * speed
	if player.is_on_floor():
		player.velocity.y = 0.0
		if Input.is_key_pressed(KEY_SPACE) and not book_open:
			player.velocity.y = 6.0
	else:
		player.velocity.y -= 20.0 * delta
	player.move_and_slide()

func _process(_delta):
	_find_target()
	if not unlocked.has("compass") and player.position.length() > 35.0:
		_unlock("compass")
	if book_open:
		hint.text = "Q / ←  trang trước    E / →  trang sau    J  đóng sổ"
	elif target >= 0:
		var id = items[target].id
		hint.text = ("[E] Quan sát: " if id == "water" else "[E] Nhặt: ") + names[id]
	else:
		hint.text = "WASD di chuyển · Shift chạy · E nhặt · J mở sổ tay"
	var s = ""
	for k in inv:
		s += "%s x%d    " % [names[k], inv[k]]
	hud.text = s if s != "" else "Túi đồ trống"
