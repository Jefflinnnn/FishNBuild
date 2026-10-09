extends Node2D
## Grid MVP: walk around a 16x16 isometric lake, toggle build mode,
## place dock tiles on the water's edge and remove them.

const START_CELL := Vector2i(3, 3)

@onready var grid: IsoGrid = $World/Ground
@onready var player: Node2D = $World/Objects/Player
@onready var cursor: Node2D = $World/Cursor
@onready var hud: Label = $UI/Hud

var build_mode := false
var hovered := Vector2i(-1, -1)


func _enter_tree() -> void:
	_register_inputs()


func _ready() -> void:
	player.grid = grid
	player.global_position = grid.cell_to_world(START_CELL)
	_update_hud()


func _process(_delta: float) -> void:
	hovered = grid.world_to_cell(get_global_mouse_position())
	cursor.visible = build_mode and grid.in_bounds(hovered)
	if cursor.visible:
		cursor.global_position = grid.cell_to_world(hovered)
		cursor.valid = grid.can_place_dock(hovered) or _can_remove(hovered)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build"):
		build_mode = not build_mode
	elif build_mode and event is InputEventMouseButton and event.pressed:
		var cell := grid.world_to_cell(get_global_mouse_position())
		if event.button_index == MOUSE_BUTTON_LEFT and grid.can_place_dock(cell):
			grid.set_kind(cell, IsoGrid.Kind.DOCK)
		elif event.button_index == MOUSE_BUTTON_RIGHT and _can_remove(cell):
			grid.set_kind(cell, IsoGrid.Kind.WATER)


func _can_remove(cell: Vector2i) -> bool:
	# Never pull the dock out from under the player.
	return grid.can_remove_dock(cell) and cell != player.current_cell()


func _update_hud() -> void:
	var mode := "BUILD  (left-click water edge: place dock, right-click dock: remove)" if build_mode else "WALK"
	hud.text = "WASD / arrows: move    B: build mode\nMode: %s\nPlayer cell: %s    Mouse cell: %s" % [
		mode, player.current_cell(), hovered if grid.in_bounds(hovered) else "-"]


func _register_inputs() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"toggle_build": [KEY_B],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
