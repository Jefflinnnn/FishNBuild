extends Node2D
## Cast -> wait -> bite -> reel. Lives in the y-sorted Objects layer; its position
## is the bobber, so it sorts correctly against the player.

signal caught(fish: FishData)
signal message(text: String)

enum State { IDLE, CASTING, WAITING, BITE, REELING }

const CAST_RANGE := 3          # cells
const CAST_TIME := 0.45        # seconds of bobber flight
const WAIT_MIN := 2.0
const WAIT_MAX := 5.0
const BITE_WINDOW := 1.2
const ROD_TIP := Vector2(22, -70)  # relative to the player's feet

var grid: IsoGrid
var player: Node2D
var reel_bar: Control
## Lamps and other decor can lower this later (1.0 = normal).
var wait_multiplier := 1.0

var state := State.IDLE
var _timer := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _fish: FishData
var _t := 0.0  # free-running clock for bobbing / ripples


func _ready() -> void:
	visible = false


func is_busy() -> bool:
	return state != State.IDLE


func can_cast() -> bool:
	return state == State.IDLE and _pick_target() != Vector2i(-1, -1)


## Space bar. What it does depends on the state.
func press_action() -> void:
	match state:
		State.IDLE:
			_try_cast()
		State.WAITING:
			message.emit("Reeled in too early.")
			_reset()
		State.BITE:
			_start_reel()
		State.REELING:
			reel_bar.press()


func _try_cast() -> void:
	if Game.bucket_full():
		message.emit("Bucket is full. Sell your fish at the box.")
		return
	var cell := _pick_target()
	if cell == Vector2i(-1, -1):
		message.emit("Get closer to the water to cast.")
		return
	_from = _rod_tip()
	_to = grid.cell_to_world(cell)
	_timer = 0.0
	state = State.CASTING
	visible = true
	Sfx.play("cast")


func _rod_tip() -> Vector2:
	var side := -1.0 if player.facing.x < 0 else 1.0
	return player.global_position + ROD_TIP * Vector2(side, 1)


## Best water cell within range, preferring the direction the player faces.
func _pick_target() -> Vector2i:
	var here: Vector2i = grid.world_to_cell(player.global_position)
	var best := Vector2i(-1, -1)
	var best_score := -INF
	for dy in range(-CAST_RANGE, CAST_RANGE + 1):
		for dx in range(-CAST_RANGE, CAST_RANGE + 1):
			var c := here + Vector2i(dx, dy)
			if not grid.is_water(c):
				continue
			var d: Vector2 = grid.cell_to_world(c) - player.global_position
			var score: float = d.normalized().dot(player.facing) * 2.0 - d.length() / 250.0
			if score > best_score:
				best_score = score
				best = c
	return best


func _process(delta: float) -> void:
	_t += delta
	match state:
		State.CASTING:
			_timer += delta
			var k := clampf(_timer / CAST_TIME, 0.0, 1.0)
			global_position = _from.lerp(_to, k) + Vector2(0, -sin(k * PI) * 90.0)
			if k >= 1.0:
				Sfx.play("splash")
				state = State.WAITING
				_timer = randf_range(WAIT_MIN, WAIT_MAX) * wait_multiplier
		State.WAITING:
			_timer -= delta
			if _timer <= 0.0:
				_fish = Game.roll_fish()
				state = State.BITE
				_timer = BITE_WINDOW
				Sfx.play("bite")
				message.emit("! Bite! Press Space!")
		State.BITE:
			_timer -= delta
			if _timer <= 0.0:
				message.emit("It got away...")
				_reset()
	if visible:
		queue_redraw()


func _start_reel() -> void:
	state = State.REELING
	reel_bar.finished.connect(_on_reel_finished, CONNECT_ONE_SHOT)
	reel_bar.start(_fish.difficulty)


func _on_reel_finished(success: bool) -> void:
	if success:
		Game.add_fish(_fish)
		caught.emit(_fish)
	else:
		message.emit("The %s slipped off the hook." % _fish.display_name)
	_reset()


func _reset() -> void:
	state = State.IDLE
	_fish = null
	visible = false


func _draw() -> void:
	if state == State.IDLE:
		return
	var bob := Vector2.ZERO
	if state == State.WAITING:
		bob.y = sin(_t * 3.0) * 2.0
	elif state in [State.BITE, State.REELING]:
		bob.y = 6.0 + sin(_t * 30.0) * 2.0
	# Line from rod tip to bobber.
	var tip := to_local(_rod_tip())
	draw_line(tip, bob + Vector2(0, -6), Color(1, 1, 1, 0.8), 1.5, true)
	# Ripples once it's in the water.
	if state != State.CASTING:
		var rings := 3 if state == State.BITE else 1
		for i in rings:
			var p := fmod(_t * (1.6 if state == State.BITE else 0.6) + i / float(rings), 1.0)
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
			draw_arc(Vector2.ZERO, 8 + p * 30, 0, TAU, 32, Color(1, 1, 1, 0.7 * (1.0 - p)), 2.0, true)
			draw_set_transform(Vector2.ZERO)
	# Bobber: red top, white bottom.
	draw_circle(bob + Vector2(0, -6), 7, Color("e8e8e8"))
	draw_circle(bob + Vector2(0, -9), 5, Color("e2483d"))
