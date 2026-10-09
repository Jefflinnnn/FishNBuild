class_name IsoGrid
extends Node3D
## 16x16 tile grid in 3D. One tile = 1 m. Cell (x, y) covers world x..x+1, z..z+1
## (the grid's y is world z). Tiles are placeholder boxes until art models land:
## grass is a raised block, water sits lower with a lakebed, docks are planks.

signal cell_changed(cell: Vector2i, kind: int)

const SIZE := 16
const GROUND_Y := 0.0      # top of grass / docks: where things stand
const WATER_Y := -0.22     # water surface
const BASE_Y := -1.2       # bottom of the island

enum Kind { GRASS, WATER, DOCK }

const GRASS_A := Color("8cc46b")
const GRASS_B := Color("83bb63")
const DIRT := Color("8a6a4a")
const WATER := Color(0.36, 0.66, 0.88)
const LAKEBED := Color("3f6f8f")
const WOOD := Color("b58350")

# Lake: an ellipse of water toward the camera side of the map.
const LAKE_CENTER := Vector2(10.5, 9.5)
const LAKE_RADIUS := Vector2(4.6, 5.2)

## Cells occupied by solid objects (selling box, furniture). cell -> node
var blocked := {}

var _kinds := {}           # Vector2i -> Kind
var _tiles := {}           # Vector2i -> Node3D


func _ready() -> void:
	_generate_map()


func _generate_map() -> void:
	for y in SIZE:
		for x in SIZE:
			var p := (Vector2(x, y) - LAKE_CENTER) / LAKE_RADIUS
			set_kind(Vector2i(x, y), Kind.WATER if p.length_squared() <= 1.0 else Kind.GRASS)


# --- Queries -----------------------------------------------------------------

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE and cell.y < SIZE


func get_kind(cell: Vector2i) -> int:
	return _kinds.get(cell, -1)


func is_walkable(cell: Vector2i) -> bool:
	if blocked.has(cell):
		return false
	var k := get_kind(cell)
	return k == Kind.GRASS or k == Kind.DOCK


func is_water(cell: Vector2i) -> bool:
	return get_kind(cell) == Kind.WATER


func neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [cell + Vector2i.RIGHT, cell + Vector2i.LEFT, cell + Vector2i.DOWN, cell + Vector2i.UP]


## World position -> grid cell.
func world_to_cell(pos: Vector3) -> Vector2i:
	var local := to_local(pos)
	return Vector2i(floori(local.x), floori(local.z))


## Grid cell -> world position of the tile's top center (where things stand).
func cell_to_world(cell: Vector2i) -> Vector3:
	var y := WATER_Y if is_water(cell) else GROUND_Y
	return to_global(Vector3(cell.x + 0.5, y, cell.y + 0.5))


## A dock can go on water that touches land or another dock.
func can_place_dock(cell: Vector2i) -> bool:
	if not is_water(cell):
		return false
	for n in neighbors(cell):
		if is_walkable(n) or get_kind(n) == Kind.DOCK:
			return true
	return false


func can_remove_dock(cell: Vector2i) -> bool:
	return get_kind(cell) == Kind.DOCK


# --- Tiles -------------------------------------------------------------------

func set_kind(cell: Vector2i, kind: int) -> void:
	_kinds[cell] = kind
	if _tiles.has(cell):
		_tiles[cell].queue_free()
	var t := Node3D.new()
	t.position = Vector3(cell.x + 0.5, 0, cell.y + 0.5)
	add_child(t)
	_tiles[cell] = t
	match kind:
		Kind.GRASS:
			MeshKit.box(t, Vector3(1, -BASE_Y - 0.12, 1), DIRT, Vector3(0, BASE_Y, 0))
			var green := GRASS_A if (cell.x + cell.y) % 2 == 0 else GRASS_B
			MeshKit.box(t, Vector3(1, 0.12, 1), green, Vector3(0, -0.12, 0))
		Kind.WATER, Kind.DOCK:
			MeshKit.box(t, Vector3(1, -0.52 - BASE_Y, 1), DIRT, Vector3(0, BASE_Y, 0))
			MeshKit.box(t, Vector3(1, 0.02, 1), LAKEBED, Vector3(0, -0.52, 0))
			MeshKit.box(t, Vector3(1, 0.3, 1), WATER, Vector3(0, -0.52, 0))
			if kind == Kind.DOCK:
				_build_dock(t)
	cell_changed.emit(cell, kind)


func _build_dock(t: Node3D) -> void:
	# Four planks with small gaps, resting on corner posts.
	for i in 4:
		var x := -0.375 + i * 0.25
		MeshKit.box(t, Vector3(0.23, 0.08, 1.0), WOOD.darkened(0.06 * (i % 2)), Vector3(x, GROUND_Y - 0.08, 0))
	for c in [Vector2(-0.42, -0.42), Vector2(0.42, -0.42), Vector2(-0.42, 0.42), Vector2(0.42, 0.42)]:
		MeshKit.cylinder(t, 0.05, 0.5, WOOD.darkened(0.3), Vector3(c.x, -0.55, c.y))
