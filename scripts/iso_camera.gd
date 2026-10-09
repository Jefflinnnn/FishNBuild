extends Camera3D
## Fixed isometric camera: orthographic, 45 degree yaw, 30 degree pitch (the 2:1
## "pixel isometric" angle). Smoothly follows a target and can zoom with the wheel.

@export var yaw_deg := 45.0
@export var pitch_deg := -30.0
@export var distance := 30.0
@export var follow_speed := 6.0
@export var zoom_min := 7.0
@export var zoom_max := 22.0

var target: Node3D
var _focus := Vector3.ZERO


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	if size <= 0.0:
		size = 12.0
	rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0)
	if target:
		_focus = target.global_position
	_place()


func snap() -> void:
	if target:
		_focus = target.global_position
	_place()


func _process(delta: float) -> void:
	if target:
		_focus = _focus.lerp(target.global_position, minf(1.0, follow_speed * delta))
	_place()


func _place() -> void:
	global_position = _focus + global_basis.z * distance


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			size = clampf(size - 1.0, zoom_min, zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			size = clampf(size + 1.0, zoom_min, zoom_max)


## Where the mouse ray hits the horizontal plane at height y.
func mouse_on_plane(y := 0.0) -> Variant:
	var mp := get_viewport().get_mouse_position()
	var origin := project_ray_origin(mp)
	var dir := project_ray_normal(mp)
	if is_zero_approx(dir.y):
		return null
	var t := (y - origin.y) / dir.y
	return origin + dir * t
