extends CanvasLayer
var hud; var hint; var toast
func _ready():
	var dot = ColorRect.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.color = Color(1, 1, 1, 0.8)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.offset_left = -2
	dot.offset_right = 2
	dot.offset_top = -2
	dot.offset_bottom = 2
	add_child(dot)
	hud = Label.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 20)
	add_child(hud)
	hint = Label.new()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.position = Vector2(16, 604)
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color("ffe9a8"))
	add_child(hint)
	toast = Label.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.position = Vector2(340, 70)
	toast.add_theme_font_size_override("font_size", 26)
	toast.add_theme_color_override("font_color", Color("ffe9a8"))
	toast.modulate.a = 0.0
	add_child(toast)

func show_notification(text):
	toast.text = text
	toast.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(toast, "modulate:a", 0.0, 0.6)

# ---------------- Gameplay ----------------

func update_display(inventory: Dictionary, names: Dictionary, hint_text: String):
	hint.text = hint_text
	var text = ""
	for id in inventory:
		text += "%s x%d    " % [names[id], inventory[id]]
	hud.text = text if text != "" else "Túi đồ trống"
