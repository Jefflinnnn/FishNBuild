extends Node2D
## Placeholder player: walks in screen space (WASD / arrows), blocked by water.
## Swap _draw() for an AnimatedSprite2D once character.png lands.

@export var speed := 260.0

var grid: IsoGrid
## Last screen direction moved in; fishing casts this way.
var facing := Vector2(1, 0.5).normalized()
## Set while fishing so the player stays put.
var locked := false


func _process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO or locked:
		return
	facing = dir.normalized()
	queue_redraw()
	# Halve vertical speed so movement feels right on a 2:1 isometric floor.
	var step := Vector2(dir.x, dir.y * 0.5).normalized() * speed * delta
	# Try the full step, then each axis alone so the player slides along shorelines.
	for s in [step, Vector2(step.x, 0), Vector2(0, step.y)]:
		if s != Vector2.ZERO and _can_stand(global_position + s):
			global_position += s
			return


func _can_stand(pos: Vector2) -> bool:
	return grid == null or grid.is_walkable(grid.world_to_cell(pos))


func current_cell() -> Vector2i:
	return grid.world_to_cell(global_position)


func _draw() -> void:
	# Origin is the feet, so Y-sorting against other objects works.
	draw_set_transform(Vector2(0, 0), 0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 22, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-16, -64, 32, 58), Color("f2a65a"))
	draw_circle(Vector2(0, -76), 16, Color("ffe0bd"))
	var side := -1.0 if facing.x < 0 else 1.0
	draw_circle(Vector2(6 * side, -78), 3, Color("3b2f2f"))
	# Rod: a thin stick from the hand out toward the facing side.
	draw_line(Vector2(10 * side, -40), Vector2(22 * side, -70), Color("6b4a2b"), 3.0, true)
