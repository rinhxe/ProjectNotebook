extends Node3D
var items = []
func _ready():
	_create_world()
func _create_mesh_instance(parent, mesh, color, pos = Vector3.ZERO, unshaded = false):
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

func _create_box_mesh(x, y, z):
	var b = BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

func _create_cylinder_mesh(top, bottom, h):
	var c = CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	return c

func _create_sphere_mesh(r, h):
	var s = SphereMesh.new()
	s.radius = r
	s.height = h
	return s

# ---------------- Thế giới ----------------

func _create_world():
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
	_create_mesh_instance(ground, plane, Color("3f7a3a"))
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
		_create_mesh_instance(t, _create_cylinder_mesh(0.3, 0.4, h), Color("5a3a1e"), Vector3(0, h * 0.5, 0))
		_create_mesh_instance(t, _create_cylinder_mesh(0.0, 2.0, 3.8), Color("1f5a2a"), Vector3(0, h + 1.2, 0))
		var tc = CollisionShape3D.new()
		var ts = CylinderShape3D.new()
		ts.radius = 0.45
		ts.height = h
		tc.shape = ts
		tc.position = Vector3(0, h * 0.5, 0)
		t.add_child(tc)

	_spawn_world_item("water", Vector3(14, 0, -12))
	_spawn_world_item("wood", Vector3(3, 0, -5))
	_spawn_world_item("wood", Vector3(-4, 0, -6))
	_spawn_world_item("stone", Vector3(5, 0, 3))
	_spawn_world_item("berry", Vector3(-6, 0, 4))
	_spawn_world_item("mushroom", Vector3(2, 0, 7))
	var kinds = ["wood", "wood", "wood", "stone", "stone", "berry", "berry", "mushroom", "mushroom", "mushroom"]
	for k in kinds:
		var q = Vector2(rng.randf_range(-45, 45), rng.randf_range(-45, 45))
		if q.length() < 8.0:
			q *= 2.0
		_spawn_world_item(k, Vector3(q.x, 0, q.y))

func _spawn_world_item(id, pos):
	var n = Node3D.new()
	n.position = pos
	add_child(n)
	var it = {"id": id, "node": n, "taken": false, "r": 0.0, "dot": 0.93}
	match id:
		"wood":
			var m = _create_mesh_instance(n, _create_cylinder_mesh(0.06, 0.07, 0.9), Color("8b5a2b"), Vector3(0, 0.07, 0))
			m.rotation_degrees = Vector3(0, 30, 90)
		"stone":
			_create_mesh_instance(n, _create_sphere_mesh(0.24, 0.34), Color("8f9296"), Vector3(0, 0.15, 0))
		"berry":
			_create_mesh_instance(n, _create_sphere_mesh(0.45, 0.7), Color("2d6a2d"), Vector3(0, 0.35, 0))
			for a in 7:
				var ang = a * 0.9
				_create_mesh_instance(n, _create_sphere_mesh(0.06, 0.12), Color("d02030"), Vector3(cos(ang) * 0.38, 0.3 + (a % 3) * 0.12, sin(ang) * 0.38))
		"mushroom":
			_create_mesh_instance(n, _create_cylinder_mesh(0.04, 0.05, 0.22), Color("e8e0cc"), Vector3(0, 0.11, 0))
			_create_mesh_instance(n, _create_sphere_mesh(0.14, 0.14), Color("a050d0"), Vector3(0, 0.24, 0))
		"water":
			_create_mesh_instance(n, _create_cylinder_mesh(5.0, 5.0, 0.06), Color("3a7bd5"), Vector3(0, 0.03, 0))
			it.r = 5.0
			it.dot = 0.2
	items.append(it)

# ---------------- Người chơi ----------------

