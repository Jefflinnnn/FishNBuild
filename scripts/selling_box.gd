extends Node3D
## The selling box: stand next to it and press E to sell the whole bucket.
## Uses res://art/models/selling_box.glb when it exists, otherwise a placeholder crate.

const MODEL_PATH := "res://art/models/selling_box.glb"

@export var cell := Vector2i(5, 4)

var grid: IsoGrid


func setup(g: IsoGrid) -> void:
	grid = g
	global_position = grid.cell_to_world(cell)
	grid.blocked[cell] = self
	var m := MeshKit.load_model(MODEL_PATH)
	if m:
		add_child(m)
		return
	# Placeholder crate with slats, a lid, and a gold coin on the front.
	var wood := Color("b07a48")
	MeshKit.box(self, Vector3(0.72, 0.55, 0.72), wood)
	for y in [0.12, 0.3, 0.48]:
		MeshKit.box(self, Vector3(0.76, 0.05, 0.76), wood.darkened(0.25), Vector3(0, y - 0.025, 0))
	MeshKit.box(self, Vector3(0.8, 0.07, 0.8), wood.lightened(0.15), Vector3(0, 0.55, 0))
	var coin := MeshKit.cylinder(self, 0.14, 0.04, Color("f5c84c"), Vector3.ZERO)
	coin.material_override = MeshKit.mat(Color("f5c84c"), 0.3, 0.4)
	coin.rotation = Vector3(PI / 2, 0, 0)
	coin.position = Vector3(0, 0.3, 0.38)


## True when the player stands on one of the 8 tiles around the box.
func is_player_near(player_cell: Vector2i) -> bool:
	var d := (player_cell - cell).abs()
	return maxi(d.x, d.y) == 1
