class_name FishData
extends Resource
## One fish species. Add a new .tres in res://data/fish/ to add a fish.

@export var id := ""
@export var display_name := ""
@export var price := 5
## Relative chance of being picked on a catch.
@export var weight := 1.0
## 0 = easy, 1 = hard. Shrinks the reel zone and speeds up the marker.
@export_range(0.0, 1.0) var difficulty := 0.3
@export_file("*.png") var sprite_path := ""
## Placeholder color until the sprite exists.
@export var color := Color.SILVER


func get_icon() -> Texture2D:
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		return load(sprite_path)
	return null
