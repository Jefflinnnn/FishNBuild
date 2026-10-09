extends Node2D
## The selling box: stand next to it and press E to sell the whole bucket.
## Uses res://art/selling_box.png when it exists, otherwise a placeholder crate.

const ART := "res://art/selling_box.png"

@export var cell := Vector2i(5, 4)

var grid: IsoGrid


func setup(g: IsoGrid) -> void:
	grid = g
	global_position = grid.cell_to_world(cell)
	grid.blocked[cell] = self
	if ResourceLoader.exists(ART):
		var s := Sprite2D.new()
		s.texture = load(ART)
		s.centered = false
		s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height() + 24)
		add_child(s)


## True when the player stands on one of the 8 cells around the box.
func is_player_near(player_cell: Vector2i) -> bool:
	var d := (player_cell - cell).abs()
	return maxi(d.x, d.y) == 1


func _draw() -> void:
	if get_child_count() > 0:
		return
	# Placeholder crate: an isometric box with a coin on the front.
	var w := 44.0
	var h := 22.0
	var tall := 40.0
	var top := PackedVector2Array([Vector2(0, -tall - h), Vector2(w, -tall), Vector2(0, -tall + h), Vector2(-w, -tall)])
	var left := PackedVector2Array([Vector2(-w, -tall), Vector2(0, -tall + h), Vector2(0, h), Vector2(-w, 0)])
	var right := PackedVector2Array([Vector2(w, -tall), Vector2(0, -tall + h), Vector2(0, h), Vector2(w, 0)])
	draw_colored_polygon(left, Color("9c6b3f"))
	draw_colored_polygon(right, Color("7d5330"))
	draw_colored_polygon(top, Color("c48a52"))
	draw_circle(Vector2(-22, -12), 9, Color("f5c84c"))
	draw_string(ThemeDB.fallback_font, Vector2(-26, -7), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("7a5a12"))
