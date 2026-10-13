extends RefCounted
signal notification_requested(message: String)
const TABS = ["Vật phẩm", "Chế tạo", "Sinh tồn"]
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
var unlocked = {"tips": true, "water_rule": true}
var pages: Array = entries.keys()
func get_page_content(index: int) -> Array:
	if index < 0 or index >= pages.size(): return ["", "", "", ""]
	var id = pages[index]
	if unlocked.has(id):
		return [TABS[entries[id].tab].to_upper(), entries[id].title, entries[id].text, "- %d -" % (index + 1)]
	return ["", "???", "Chưa khám phá.\nHãy đi tìm để ghi thêm trang này.", "- %d -" % (index + 1)]

func unlock_entry(id: String):
	if not entries.has(id) or unlocked.has(id):
		return
	unlocked[id] = true
	notification_requested.emit("Sổ tay đã ghi thêm: " + entries[id].title + "  (nhấn J)")

func record_discovery(id: String, inventory: Dictionary):
	unlock_entry(id)
	if inventory.get("wood", 0) >= 1 and inventory.get("stone", 0) >= 1:
		unlock_entry("axe")
	if inventory.get("wood", 0) >= 3:
		unlock_entry("campfire")

func record_travel_distance(distance: float):
	if distance > 35.0:
		unlock_entry("compass")

