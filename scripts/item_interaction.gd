extends Node
signal discovery_recorded(id: String, inventory: Dictionary)
var inv = {}
var items = []
var target = -1
var cam: Camera3D
var names = {"wood": "Gỗ", "stone": "Đá", "berry": "Quả mọng", "mushroom": "Nấm", "water": "Ao nước"}
func find_interaction_target():
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

func interact_with_target_item():
	if target < 0:
		return
	var it = items[target]
	var id = it.id
	if id != "water":
		it.taken = true
		it.node.visible = false
		inv[id] = inv.get(id, 0) + 1
	discovery_recorded.emit(id, inv)

func get_target_hint() -> String:
	if target < 0:
		return "WASD di chuyển · Shift chạy · E nhặt · J mở sổ tay"
	var id = items[target].id
	return ("[E] Quan sát: " if id == "water" else "[E] Nhặt: ") + names[id]
