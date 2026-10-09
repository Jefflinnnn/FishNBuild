class_name IsoGrid
extends TileMapLayer
## 16x16 isometric ground grid (128x64 diamonds, diamond-down layout).
## Builds a placeholder TileSet in code so the game runs before any art lands.
## When Tiffany's tileset_ground.png arrives, swap the atlas texture in _build_tileset().

signal cell_changed(cell: Vector2i, kind: int)

const SIZE := 16
const TILE := Vector2i(128, 64)

enum Kind { GRASS, WATER, DOCK }

const COLORS := {
	Kind.GRASS: Color("8cc46b"),
	Kind.WATER: Color("5aa7d8"),
	Kind.DOCK: Color("b58350"),
}

# Lake: an ellipse of water in the lower-right half of the map.
const LAKE_CENTER := Vector2(10.5, 9.5)
const LAKE_RADIUS := Vector2(4.6, 5.2)

## Cells occupied by solid objects (e.g. the selling box). cell -> node
var blocked := {}


func _ready() -> void:
	tile_set = _build_tileset()
	_generate_map()


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = TILE

	var kinds := COLORS.size()
	var img := Image.create(TILE.x * kinds, TILE.y, false, Image.FORMAT_RGBA8)
	for k in kinds:
		_paint_diamond(img, k * TILE.x, COLORS[k])

	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = TILE
	for k in kinds:
		src.create_tile(Vector2i(k, 0))
	ts.add_source(src, 0)
	return ts


func _paint_diamond(img: Image, x0: int, base: Color) -> void:
	var half := Vector2(TILE) / 2.0
	var edge := base.darkened(0.25)
	for y in TILE.y:
		for x in TILE.x:
			var d := absf(x + 0.5 - half.x) / half.x + absf(y + 0.5 - half.y) / half.y
			if d <= 1.0:
				img.set_pixel(x0 + x, y, edge if d > 0.93 else base)


func _generate_map() -> void:
	clear()
	for y in SIZE:
		for x in SIZE:
			var p := (Vector2(x, y) - LAKE_CENTER) / LAKE_RADIUS
			set_kind(Vector2i(x, y), Kind.WATER if p.length_squared() <= 1.0 else Kind.GRASS)


# --- Queries -----------------------------------------------------------------

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE and cell.y < SIZE


func get_kind(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return -1
	return get_cell_atlas_coords(cell).x


func set_kind(cell: Vector2i, kind: int) -> void:
	set_cell(cell, 0, Vector2i(kind, 0))
	cell_changed.emit(cell, kind)


func is_walkable(cell: Vector2i) -> bool:
	if blocked.has(cell):
		return false
	var k := get_kind(cell)
	return k == Kind.GRASS or k == Kind.DOCK


func is_water(cell: Vector2i) -> bool:
	return get_kind(cell) == Kind.WATER


## World position -> grid cell.
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return local_to_map(to_local(world_pos))


## Grid cell -> world position of the diamond's center.
func cell_to_world(cell: Vector2i) -> Vector2:
	return to_global(map_to_local(cell))


## A dock can go on water that touches land or another dock.
func can_place_dock(cell: Vector2i) -> bool:
	if get_kind(cell) != Kind.WATER:
		return false
	for n in get_surrounding_cells(cell):
		if is_walkable(n):
			return true
	return false


## Any dock tile can be removed (the player-standing check lives in main.gd).
func can_remove_dock(cell: Vector2i) -> bool:
	return get_kind(cell) == Kind.DOCK
