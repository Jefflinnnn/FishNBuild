extends Node
## Build mode: pick an item from the hotbar (1-6 or click), then
##   left-click  = place it / pick up an existing piece to move it / drop it
##   right-click = remove the piece under the cursor (or cancel a move)
##   R           = rotate the held item, the ghost, or the piece under the cursor 90 degrees
## Everything placed lives in `placed` (cell -> Furniture), ready for save/load.

signal message(text: String)

const LAMP_RANGE := 2
const MIN_WAIT_MULT := 0.4

var grid: IsoGrid
var player: Node3D
var objects: Node3D       # parent for placed furniture
var cursor: Node3D
var hotbar: HBoxContainer

var active := false:
	set(v):
		active = v
		if not v:
			_cancel_move()
		hotbar.visible = v
		_ghost.visible = false
		cursor.visible = false

var selected := 0
var placed := {}          # Vector2i -> Furniture

var _ghost: Furniture
var _ghost_turns := 0
var _held: Furniture      # piece being moved
var _held_from := Vector2i.ZERO
var _held_turns := 0
var _buttons: Array[Button] = []


func setup(g: IsoGrid, p: Node3D, objs: Node3D, cur: Node3D, bar: HBoxContainer) -> void:
	grid = g
	player = p
	objects = objs
	cursor = cur
	hotbar = bar
	_ghost = Furniture.new()
	objects.add_child(_ghost)
	_build_hotbar()
	select(0)
	active = false


func item() -> FurnitureData:
	return Game.furniture_table[selected]


func select(i: int) -> void:
	if i < 0 or i >= Game.furniture_table.size():
		return
	selected = i
	_ghost.setup(item(), true)
	_ghost.turns = _ghost_turns
	for b in _buttons.size():
		_buttons[b].set_pressed_no_signal(b == i)


# --- Per-frame preview ------------------------------------------------------

func update(hovered: Vector2i) -> void:
	if not active:
		return
	var inside := grid.in_bounds(hovered)
	cursor.visible = inside
	_ghost.visible = inside and _held == null and not placed.has(hovered)
	if not inside:
		if _held:
			_held.visible = false
		return
	var pos := grid.cell_to_world(hovered)
	cursor.global_position = pos + Vector3(0, 0.02, 0)
	if _held:
		var ok := _can_place(_held.data, hovered)
		_held.visible = true
		_held.global_position = _stand_pos(_held.data, hovered)
		_held.set_ghost(true, ok)
		cursor.valid = ok
	elif placed.has(hovered):
		cursor.valid = true   # can pick up / remove
	else:
		var ok := _can_place(item(), hovered) and Game.can_afford(item().price)
		_ghost.global_position = _stand_pos(item(), hovered)
		_ghost.set_ghost(true, ok)
		cursor.valid = ok or _can_remove_dock(hovered)


## Where an item stands on a tile (docks sit at deck height over the water).
func _stand_pos(d: FurnitureData, cell: Vector2i) -> Vector3:
	var p := grid.cell_to_world(cell)
	if d.is_tile:
		p.y = IsoGrid.GROUND_Y
	return p


# --- Input ------------------------------------------------------------------

func handle_input(event: InputEvent, hovered: Vector2i) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k >= KEY_1 and k <= KEY_9:
			select(k - KEY_1)
			return true
		if k == KEY_R:
			_rotate(hovered)
			return true
		if k == KEY_ESCAPE and _held:
			_cancel_move()
			return true
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_left_click(hovered)
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_right_click(hovered)
			return true
	return false


func _left_click(cell: Vector2i) -> void:
	if not grid.in_bounds(cell):
		return
	if _held:
		if _can_place(_held.data, cell):
			_put(_held, cell)
			_held.set_ghost(false)
			_held = null
		else:
			message.emit("Can't put that there.")
	elif placed.has(cell):
		_pick_up(cell)
	else:
		_place_new(cell)


func _right_click(cell: Vector2i) -> void:
	if _held:
		_cancel_move()
	elif placed.has(cell):
		var f: Furniture = placed[cell]
		_unregister(cell)
		Game.refund(f.data.price)
		f.queue_free()
	elif _can_remove_dock(cell):
		grid.set_kind(cell, IsoGrid.Kind.WATER)
		Game.refund(_dock_price())


func _rotate(cell: Vector2i) -> void:
	if _held:
		_held.turns += 1
	elif placed.has(cell):
		placed[cell].turns += 1
	else:
		_ghost_turns = (_ghost_turns + 1) % 4
		_ghost.turns = _ghost_turns


# --- Placing / moving -------------------------------------------------------

func _place_new(cell: Vector2i) -> void:
	var d := item()
	if not _can_place(d, cell):
		if d.is_tile:
			message.emit("Docks go on water next to land or another dock.")
		else:
			message.emit("Furniture goes on an empty grass or dock tile.")
		return
	if not Game.spend(d.price):
		message.emit("Not enough money for a %s ($%d)." % [d.display_name, d.price])
		return
	if d.is_tile:
		grid.set_kind(cell, IsoGrid.Kind.DOCK)
		return
	_spawn_piece(d, cell, _ghost_turns)


## Spawn a piece from saved data (for save/load).
func spawn(id: String, cell: Vector2i, turns := 0) -> void:
	for d in Game.furniture_table:
		if d.id == id and not d.is_tile:
			_spawn_piece(d, cell, turns)
			return


func _spawn_piece(d: FurnitureData, cell: Vector2i, turns: int) -> void:
	var f := Furniture.new()
	objects.add_child(f)
	f.setup(d)
	f.turns = turns
	_put(f, cell)


func _put(f: Furniture, cell: Vector2i) -> void:
	f.cell = cell
	f.global_position = grid.cell_to_world(cell)
	f.visible = true
	placed[cell] = f
	grid.blocked[cell] = f


func _unregister(cell: Vector2i) -> void:
	placed.erase(cell)
	grid.blocked.erase(cell)


func _pick_up(cell: Vector2i) -> void:
	_held = placed[cell]
	_held_from = cell
	_held_turns = _held.turns
	_unregister(cell)


func _cancel_move() -> void:
	if _held == null:
		return
	_held.turns = _held_turns
	_held.set_ghost(false)
	_put(_held, _held_from)
	_held = null


func _can_place(d: FurnitureData, cell: Vector2i) -> bool:
	if not grid.in_bounds(cell):
		return false
	if d.is_tile:
		return grid.can_place_dock(cell)
	if grid.blocked.has(cell) or cell == player.current_cell():
		return false
	var k := grid.get_kind(cell)
	return k == IsoGrid.Kind.GRASS or k == IsoGrid.Kind.DOCK


func _can_remove_dock(cell: Vector2i) -> bool:
	return grid.can_remove_dock(cell) and not grid.blocked.has(cell) and cell != player.current_cell()


func _dock_price() -> int:
	for d in Game.furniture_table:
		if d.is_tile:
			return d.price
	return 0


# --- Fishing effect ---------------------------------------------------------

## Multiplier for the bite wait at a cell: each lamp within LAMP_RANGE tiles cuts it.
func wait_multiplier_at(cell: Vector2i) -> float:
	var m := 1.0
	for c: Vector2i in placed:
		var d: Vector2i = (c - cell).abs()
		if maxi(d.x, d.y) <= LAMP_RANGE:
			m *= 1.0 - placed[c].data.bite_speed_bonus
	return maxf(m, MIN_WAIT_MULT)


# --- Hotbar -----------------------------------------------------------------

func _build_hotbar() -> void:
	for i in Game.furniture_table.size():
		var d := Game.furniture_table[i]
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(110, 58)
		b.text = "%d  %s\n%s" % [i + 1, d.display_name, "free" if Game.FREE_BUILD else "$%d" % d.price]
		b.pressed.connect(select.bind(i))
		hotbar.add_child(b)
		_buttons.append(b)
