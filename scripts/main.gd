extends Node2D
## Grid MVP: walk around a 16x16 isometric lake, fish from the shore or a dock,
## sell the bucket at the selling box, and build docks and furniture in build mode.

const START_CELL := Vector2i(3, 3)

@onready var grid: IsoGrid = $World/Ground
@onready var player: Node2D = $World/Objects/Player
@onready var fishing: Node2D = $World/Objects/Fishing
@onready var selling_box: Node2D = $World/Objects/SellingBox
@onready var cursor: Node2D = $World/Cursor
@onready var fx: Node2D = $World/Fx
@onready var hud: Label = $UI/Hud
@onready var hint: Label = $UI/Hint
@onready var reel_bar: Control = $UI/ReelBar
@onready var builder: Node = $Builder
@onready var hotbar: HBoxContainer = $UI/Hotbar

var hovered := Vector2i(-1, -1)
var _message := ""
var _message_time := 0.0


func _enter_tree() -> void:
	_register_inputs()


func _ready() -> void:
	player.grid = grid
	player.global_position = grid.cell_to_world(START_CELL)
	selling_box.setup(grid)
	fishing.grid = grid
	fishing.player = player
	fishing.reel_bar = reel_bar
	fishing.caught.connect(_on_caught)
	fishing.message.connect(_show_message)
	builder.setup(grid, player, $World/Objects, cursor, hotbar)
	builder.message.connect(_show_message)
	_show_message("Walk to the water and press Space to cast.", 6.0)


func _process(delta: float) -> void:
	player.locked = fishing.is_busy()
	hovered = grid.world_to_cell(get_global_mouse_position())
	builder.update(hovered)
	if _message_time > 0.0:
		_message_time -= delta
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build") and not fishing.is_busy():
		builder.active = not builder.active
	elif builder.active:
		builder.handle_input(event, grid.world_to_cell(get_global_mouse_position()))
	elif event.is_action_pressed("action"):
		if not fishing.is_busy():
			fishing.wait_multiplier = builder.wait_multiplier_at(player.current_cell())
		fishing.press_action()
	elif event.is_action_pressed("interact") and _near_box():
		_sell()


func _near_box() -> bool:
	return selling_box.is_player_near(player.current_cell()) and not fishing.is_busy()


func _sell() -> void:
	if Game.bucket.is_empty():
		_show_message("Your bucket is empty. Go catch something!")
		return
	var n := Game.bucket.size()
	var earned := Game.sell_all()
	Sfx.play("coin")
	PopupText.spawn(fx, selling_box.global_position + Vector2(0, -80), "+$%d" % earned, Color("ffd34d"), 32)
	_show_message("Sold %d fish for $%d." % [n, earned])


func _on_caught(fish: FishData) -> void:
	PopupText.spawn(fx, player.global_position + Vector2(0, -110), "%s!  ($%d)" % [fish.display_name, fish.price],
		fish.color.lightened(0.3))
	_show_message("Caught a %s. Bucket %d/%d." % [fish.display_name, Game.bucket.size(), Game.BUCKET_CAP])


func _show_message(text: String, seconds := 2.5) -> void:
	_message = text
	_message_time = seconds


func _update_hud() -> void:
	hud.text = "$%d\nBucket: %d/%d  (worth $%d)" % [
		Game.money, Game.bucket.size(), Game.BUCKET_CAP, Game.bucket_value()]
	var lines: PackedStringArray = []
	if _message_time > 0.0:
		lines.append(_message)
	if builder.active:
		lines.append("BUILD  -  1-6 / click: pick item   Left-click: place, or pick up to move   Right-click: remove   R: flip   B: done")
	elif not fishing.is_busy():
		var prompts: PackedStringArray = ["WASD: move", "B: build"]
		if fishing.can_cast():
			var m: float = builder.wait_multiplier_at(player.current_cell())
			prompts.append("Space: cast" + ("  (lamp nearby: faster bites)" if m < 1.0 else ""))
		if _near_box() and not Game.bucket.is_empty():
			prompts.append("E: sell fish ($%d)" % Game.bucket_value())
		lines.append("   ".join(prompts))
	hint.text = "\n".join(lines)


func _register_inputs() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"toggle_build": [KEY_B],
		"action": [KEY_SPACE],
		"interact": [KEY_E],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
