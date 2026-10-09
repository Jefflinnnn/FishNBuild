extends Node2D
## Diamond outline drawn over the hovered cell. Green = valid action, red = not.

var valid := true:
	set(v):
		valid = v
		queue_redraw()


func _draw() -> void:
	var h := Vector2(IsoGrid.TILE) / 2.0
	var pts := PackedVector2Array([
		Vector2(0, -h.y), Vector2(h.x, 0), Vector2(0, h.y), Vector2(-h.x, 0), Vector2(0, -h.y)
	])
	var c := Color(0.4, 1.0, 0.5) if valid else Color(1.0, 0.35, 0.35)
	draw_colored_polygon(pts.slice(0, 4), Color(c, 0.25))
	draw_polyline(pts, c, 3.0, true)
