class_name FurnitureData
extends Resource
## One placeable item. Add a .tres in res://data/furniture/ to add an item to build mode.

@export var id := ""
@export var display_name := ""
@export var price := 10
## Position in the build hotbar (lower = further left).
@export var order := 0
## Placeholder shape until art lands: dock, chair, desk, coffee, lamp, shrub.
@export var shape := ""
@export var color := Color.WHITE
@export_file("*.png") var sprite_path := ""
## Tile items (the dock) change the ground instead of standing on it.
@export var is_tile := false
## Fishing effect: each one within 2 tiles of the player cuts the bite wait by this fraction.
@export_range(0.0, 0.9) var bite_speed_bonus := 0.0


func get_texture() -> Texture2D:
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		return load(sprite_path)
	return null
