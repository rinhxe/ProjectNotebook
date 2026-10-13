extends Node3D
const INK = Color("24180f")
const LEATHER = Color("4a2e1a")
const PAPER = Color("efe3c0")
var cover: Node3D
var leaf: Node3D
var left_labels: Dictionary
var right_labels: Dictionary
var leaf_front: Dictionary
var leaf_back: Dictionary
var page_surfaces: Array[MeshInstance3D] = []
func _ready():
	_create_book_geometry()
func _create_mesh_instance(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3):
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = pos
	parent.add_child(instance)
	return instance

func _create_box_mesh(size: Vector3) -> BoxMesh:
	var mesh = BoxMesh.new()
	mesh.size = size
	return mesh

func _create_book_geometry():
	_create_mesh_instance(self, _create_box_mesh(Vector3(0.32, 0.44, 0.012)), LEATHER, Vector3(0.16, 0, -0.052))
	cover = Node3D.new()
	add_child(cover)
	_create_mesh_instance(self, _create_box_mesh(Vector3(0.012, 0.44, 0.07)), Color("33200f"), Vector3(0, 0, -0.02))
	# Nối mép bìa (z = 0.04) với trục gáy (z = 0).
	# Dải nối quay cùng bìa nên không hở khi bìa mở qua các góc trung gian.
	_create_mesh_instance(cover, _create_box_mesh(Vector3(0.012, 0.44, 0.052)), LEATHER, Vector3(0, 0, 0.02))
	# Sách đóng che cả hai trang; khi mở bìa, hai trang hiện ra bên dưới.
	page_surfaces.append(_create_mesh_instance(self, _create_box_mesh(Vector3(0.30, 0.40, 0.012)), PAPER, Vector3(0.155, 0, -0.03)))
	# Mặt trái nằm trong bìa trước và gập cùng bìa quanh gáy.
	page_surfaces.append(_create_mesh_instance(cover, _create_box_mesh(Vector3(0.30, 0.40, 0.012)), PAPER, Vector3(0.155, 0, 0.03)))
	left_labels = _create_page_labels(cover, Vector3(0.155, 0, 0.021), 180.0)
	right_labels = _create_page_labels(self, Vector3(0.155, 0, -0.021))
	_set_page_content_visible(true)

	leaf = Node3D.new()
	leaf.visible = false
	# Bản lề nằm trên mép trong của giấy, sát mặt chồng trang.
	leaf.position.z = -0.018
	add_child(leaf)
	_create_mesh_instance(leaf, _create_box_mesh(Vector3(0.305, 0.40, 0.004)), Color("f6ecca"), Vector3(0.1525, 0, 0))
	leaf_front = _create_page_labels(leaf, Vector3(0.155, 0, 0.003))
	leaf_back = _create_page_labels(leaf, Vector3(0.155, 0, -0.003), 180.0)

	# Khi đóng, bìa trước và bìa sau chồng lên nhau ở bên phải gáy.
	_create_mesh_instance(cover, _create_box_mesh(Vector3(0.32, 0.44, 0.012)), LEATHER, Vector3(0.16, 0, 0.04))
	_create_mesh_instance(cover, _create_box_mesh(Vector3(0.20, 0.12, 0.002)), Color("c9a24b"), Vector3(0.16, 0.06, 0.047))
	var title = Label3D.new()
	title.text = "SỔ TAY\nSINH TỒN"
	title.pixel_size = 0.0006
	title.font_size = 64
	title.modulate = Color("21150c")
	title.outline_size = 0
	title.double_sided = false
	title.position = Vector3(0.16, 0.06, 0.0495)
	cover.add_child(title)

func _create_page_labels(parent: Node3D, pos: Vector3, yaw := 0.0) -> Dictionary:
	var labels := {}
	var definitions = [["chap", 0.155, 26, Color("735522")], ["title", 0.105, 44, Color("712222")], ["body", 0.0, 32, INK], ["foot", -0.17, 24, Color("735522")]]
	for definition in definitions:
		var label := Label3D.new()
		label.name = definition[0]
		label.pixel_size = 0.0005
		label.font_size = definition[2]
		label.modulate = definition[3]
		label.outline_size = 0
		label.outline_modulate = Color(0, 0, 0, 0)
		label.width = 500.0
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.double_sided = false
		label.position = Vector3(0, definition[1], 0)
		label.rotation_degrees.y = yaw
		parent.add_child(label)
		labels[definition[0]] = label
	var holder := Node3D.new()
	parent.remove_child(labels.chap)
	parent.remove_child(labels.title)
	parent.remove_child(labels.body)
	parent.remove_child(labels.foot)
	holder.position = pos
	holder.name = "PageLabels"
	parent.add_child(holder)
	for label in labels.values(): holder.add_child(label)
	return labels

func _set_page_content_visible(value: bool):
	for surface in page_surfaces:
		surface.visible = value
	for label in left_labels.values(): label.visible = value
	for label in right_labels.values(): label.visible = value

