extends Node3D

const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/player_controller.gd")
const Interaction = preload("res://scripts/item_interaction.gd")
const Hud = preload("res://scripts/game_hud.gd")
const BOOK_SCENE = preload("res://scenes/book.tscn")

var world = World.new()
var player = Player.new()
var interaction = Interaction.new()
var hud = Hud.new()
var book = BOOK_SCENE.instantiate()

func _ready():
	add_child(world)
	add_child(player)
	add_child(hud)
	add_child(interaction)
	interaction.items = world.items
	interaction.cam = player.cam
	player.interaction_requested.connect(interaction.interact_with_target_item)
	interaction.discovery_recorded.connect(book.record_discovery)
	book.notification_requested.connect(hud.show_notification)
	book.initialize_book(player.cam)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	player.controls_locked = book.is_open
	interaction.find_interaction_target()
	book.record_travel_distance(player.position.length())
	var hint = book.get_reading_hint() if book.is_open else interaction.get_target_hint()
	hud.update_display(interaction.inv, interaction.names, hint)