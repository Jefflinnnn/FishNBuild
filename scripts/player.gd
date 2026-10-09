extends Node3D
## Placeholder player: walks relative to the camera (WASD / arrows), blocked by
## water and objects. Uses res://art/models/character.glb when it exists.

const MODEL_PATH := "res://art/models/character.glb"
const TURN_SPEED := 14.0

@export var speed := 3.6   # metres per second

var grid: IsoGrid
## Camera yaw in radians, so W always walks "up the screen".
var camera_yaw := deg_to_rad(45.0)
## Ground direction the player faces (x, z); fishing casts this way.
var facing := Vector3(-1, 0, -1).normalized()
## Set while fishing so the player stays put.
var locked := false

@onready var model: Node3D = $Model
@onready var rod_tip: Marker3D = $Model/RodTip


func _ready() -> void:
	var m := MeshKit.load_model(MODEL_PATH)
	if m:
		# Made facing Blender's Front view (imports facing +Z); the game's forward is -Z.
		m.rotation.y = PI
		model.add_child(m)
	else:
		_build_placeholder()


func _process(delta: float) -> void:
	var target_yaw := atan2(-facing.x, -facing.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_yaw, minf(1.0, TURN_SPEED * delta))
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input == Vector2.ZERO or locked:
		return
	# Screen-relative: rotate the input by the camera's yaw onto the ground plane.
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_yaw).normalized()
	facing = dir
	var step := dir * speed * delta
	# Try the full step, then each axis alone so the player slides along shorelines.
	for s in [step, Vector3(step.x, 0, 0), Vector3(0, 0, step.z)]:
		if s != Vector3.ZERO and _can_stand(global_position + s):
			global_position += s
			return


func _can_stand(pos: Vector3) -> bool:
	return grid == null or grid.is_walkable(grid.world_to_cell(pos))


func current_cell() -> Vector2i:
	return grid.world_to_cell(global_position)


func rod_tip_position() -> Vector3:
	return rod_tip.global_position


func _build_placeholder() -> void:
	# Faces local -Z. Body, head, eyes, hat, and a rod held out front.
	MeshKit.capsule(model, 0.2, 0.75, Color("f2a65a"), Vector3(0, 0.0, 0))
	MeshKit.sphere(model, 0.19, Color("ffe0bd"), Vector3(0, 0.93, 0))
	MeshKit.sphere(model, 0.03, Color("3b2f2f"), Vector3(-0.07, 0.96, -0.17))
	MeshKit.sphere(model, 0.03, Color("3b2f2f"), Vector3(0.07, 0.96, -0.17))
	MeshKit.cylinder(model, 0.24, 0.05, Color("e8d38a"), Vector3(0, 1.05, 0))
	MeshKit.cylinder(model, 0.14, 0.14, Color("e8d38a"), Vector3(0, 1.08, 0), 0.11)
	var rod := MeshKit.cylinder(model, 0.018, 1.0, Color("6b4a2b"))
	# Rod from the hand (0.2, 0.45, -0.15) angled up and forward to the tip.
	var hand := Vector3(0.2, 0.45, -0.15)
	var tip := rod_tip.position
	rod.position = (hand + tip) / 2.0
	rod.look_at_from_position(rod.position, tip, Vector3.UP)
	rod.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	(rod.mesh as CylinderMesh).height = hand.distance_to(tip)
