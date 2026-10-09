class_name Furniture
extends Node2D
## A placed (or ghost) piece of furniture. Origin = center of its tile's diamond,
## so Y-sorting works. Draws a placeholder shape until its PNG exists.

var data: FurnitureData
var cell := Vector2i.ZERO
var flipped := false:
	set(v):
		flipped = v
		scale.x = -1.0 if v else 1.0

var _sprite: Sprite2D


func setup(d: FurnitureData) -> void:
	data = d
	if _sprite:
		_sprite.queue_free()
		_sprite = null
	var tex := d.get_texture()
	if tex:
		_sprite = Sprite2D.new()
		_sprite.texture = tex
		# Bottom of the art sits on the diamond's lower point (+32 px).
		_sprite.offset = Vector2(0, -tex.get_height() / 2.0 + IsoGrid.TILE.y / 2.0)
		add_child(_sprite)
	queue_redraw()


func _draw() -> void:
	if data == null or _sprite:
		return
	var c := data.color
	match data.shape:
		"dock":
			var h := Vector2(IsoGrid.TILE) / 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(0, -h.y), Vector2(h.x, 0), Vector2(0, h.y), Vector2(-h.x, 0)]), c)
		"chair":
			_box(Vector2(-6, -10), 18, 9, 58, c.darkened(0.15))   # back rest
			_box(Vector2(4, 4), 20, 10, 24, c)                     # seat
		"desk":
			_box(Vector2.ZERO, 48, 24, 38, c)
			draw_line(Vector2(-30, -10), Vector2(-14, -2), c.darkened(0.45), 2.0)  # drawer
			_box(Vector2(14, -38), 10, 5, 14, Color("e9e4d8"))     # paper stack
		"coffee":
			_ellipse(Vector2.ZERO, Vector2(18, 9), Color(0, 0, 0, 0.2))
			draw_rect(Rect2(-3, -26, 6, 26), c.darkened(0.5))
			_ellipse(Vector2(0, -28), Vector2(24, 12), Color("8a5a3c"))
			draw_rect(Rect2(-6, -44, 12, 14), c)                   # cup
			_ellipse(Vector2(0, -44), Vector2(6, 3), Color("6b3e26"))
			draw_arc(Vector2(8, -37), 4, -PI / 2, PI / 2, 8, c, 2.0)
		"lamp":
			_ellipse(Vector2.ZERO, Vector2(54, 27), Color(1, 0.9, 0.5, 0.18))  # light pool
			_ellipse(Vector2.ZERO, Vector2(12, 6), Color("4a4a52"))
			draw_line(Vector2(0, 0), Vector2(0, -96), Color("4a4a52"), 4.0)
			draw_circle(Vector2(0, -104), 18, Color(c, 0.35))
			draw_circle(Vector2(0, -104), 11, c)
		"shrub":
			_ellipse(Vector2.ZERO, Vector2(30, 15), Color(0, 0, 0, 0.2))
			for p in [Vector2(-16, -16), Vector2(16, -16), Vector2(0, -34), Vector2(-8, -10), Vector2(10, -8)]:
				draw_circle(p, 18, c.darkened(0.1 if p.y < -20 else 0.0))
			draw_circle(Vector2(-6, -36), 6, Color("f3a6c0"))  # a flower
			draw_circle(Vector2(14, -20), 5, Color("fff2a8"))
		_:
			_box(Vector2.ZERO, 30, 15, 30, c)


## Isometric box standing on `at` (ground point), half-width hw, half-depth hh.
func _box(at: Vector2, hw: float, hh: float, tall: float, c: Color) -> void:
	var t := Vector2(0, -tall)
	var top := PackedVector2Array([at + t + Vector2(0, -hh), at + t + Vector2(hw, 0), at + t + Vector2(0, hh), at + t + Vector2(-hw, 0)])
	var left := PackedVector2Array([at + t + Vector2(-hw, 0), at + t + Vector2(0, hh), at + Vector2(0, hh), at + Vector2(-hw, 0)])
	var right := PackedVector2Array([at + t + Vector2(hw, 0), at + t + Vector2(0, hh), at + Vector2(0, hh), at + Vector2(hw, 0)])
	draw_colored_polygon(left, c.darkened(0.15))
	draw_colored_polygon(right, c.darkened(0.3))
	draw_colored_polygon(top, c.lightened(0.1))


func _ellipse(at: Vector2, r: Vector2, c: Color) -> void:
	draw_set_transform(at, 0, Vector2(1, r.y / r.x))
	draw_circle(Vector2.ZERO, r.x, c)
	draw_set_transform(Vector2.ZERO)
