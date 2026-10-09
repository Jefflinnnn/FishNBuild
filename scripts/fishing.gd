extends Node3D
## Cast -> wait -> bite -> reel. This node is the bobber; the fishing line is a
## separate top-level mesh redrawn each frame from the rod tip to the bobber.

signal caught(fish: FishData)
signal message(text: String)

enum State { IDLE, CASTING, WAITING, BITE, REELING }

const CAST_RANGE := 3          # tiles
const CAST_TIME := 0.5         # seconds of bobber flight
const CAST_ARC := 1.4          # metres of arc height
const WAIT_MIN := 2.0
const WAIT_MAX := 5.0
const BITE_WINDOW := 1.2

var grid: IsoGrid
var player: Node3D
var reel_bar: Control
## Lamps nearby lower this (1.0 = normal).
var wait_multiplier := 1.0

var state := State.IDLE
var _timer := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _fish: FishData
var _t := 0.0

var _bobber: Node3D
var _line: MeshInstance3D
var _line_mesh := ImmediateMesh.new()
var _ripples: Array[MeshInstance3D] = []


func _ready() -> void:
	_bobber = Node3D.new()
	add_child(_bobber)
	MeshKit.sphere(_bobber, 0.09, Color("eeeeee"), Vector3(0, 0.0, 0))
	MeshKit.sphere(_bobber, 0.07, Color("e2483d"), Vector3(0, 0.07, 0))
	MeshKit.cylinder(_bobber, 0.012, 0.12, Color("e2483d"), Vector3(0, 0.12, 0))

	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	_line.top_level = true
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(1, 1, 1, 0.85)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line.material_override = lm
	add_child(_line)

	for i in 3:
		var r := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.9
		torus.outer_radius = 1.0
		torus.rings = 24
		r.mesh = torus
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		r.material_override = rm
		r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		r.scale = Vector3(1, 0.2, 1)
		add_child(r)
		_ripples.append(r)
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
	_from = player.rod_tip_position()
	_to = grid.cell_to_world(cell)
	_timer = 0.0
	state = State.CASTING
	visible = true
	Sfx.play("cast")


## Best water tile within range, preferring the direction the player faces.
func _pick_target() -> Vector2i:
	var here: Vector2i = grid.world_to_cell(player.global_position)
	var best := Vector2i(-1, -1)
	var best_score := -INF
	for dy in range(-CAST_RANGE, CAST_RANGE + 1):
		for dx in range(-CAST_RANGE, CAST_RANGE + 1):
			var c := here + Vector2i(dx, dy)
			if not grid.is_water(c):
				continue
			var d: Vector3 = grid.cell_to_world(c) - player.global_position
			d.y = 0.0
			var score: float = d.normalized().dot(player.facing) * 2.0 - d.length() / 2.0
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
			global_position = _from.lerp(_to, k) + Vector3(0, sin(k * PI) * CAST_ARC, 0)
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
		_update_visuals()


func _update_visuals() -> void:
	# Bobber bobs gently while waiting and plunges + shakes on a bite.
	var bob := 0.0
	if state == State.WAITING:
		bob = sin(_t * 3.0) * 0.025
	elif state in [State.BITE, State.REELING]:
		bob = -0.08 + sin(_t * 30.0) * 0.02
	_bobber.position = Vector3(0, bob, 0)

	# Line from rod tip to bobber with a little sag.
	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var a: Vector3 = player.rod_tip_position()
	var b := _bobber.global_position + Vector3(0, 0.12, 0)
	var sag := 0.0 if state == State.CASTING else 0.35
	for i in 13:
		var k := i / 12.0
		_line_mesh.surface_add_vertex(a.lerp(b, k) - Vector3(0, sin(k * PI) * sag, 0))
	_line_mesh.surface_end()

	# Ripples on the water surface.
	var in_water := state != State.CASTING
	var rings := 3 if state == State.BITE else 1
	for i in _ripples.size():
		var r := _ripples[i]
		r.visible = in_water and i < rings
		if not r.visible:
			continue
		var p := fmod(_t * (1.6 if state == State.BITE else 0.6) + i / float(rings), 1.0)
		var s := 0.12 + p * 0.45
		r.global_position = Vector3(global_position.x, IsoGrid.WATER_Y + 0.01, global_position.z)
		r.scale = Vector3(s, 0.15, s)
		(r.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1, 0.8 * (1.0 - p))


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
	_line_mesh.clear_surfaces()
