extends Node
## Autoload "Game": money, the fish bucket, and the fish table.
## Everything save/load will need later lives here.

signal money_changed(money: int)
signal bucket_changed(bucket: Array)

const FISH_DIR := "res://data/fish/"
const BUCKET_CAP := 10

var money := 0
var bucket: Array[FishData] = []
var fish_table: Array[FishData] = []


func _ready() -> void:
	for file in ResourceLoader.list_directory(FISH_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var f := load(FISH_DIR + file) as FishData
			if f:
				fish_table.append(f)
	if fish_table.is_empty():
		push_error("No fish found in %s" % FISH_DIR)


## Weighted random pick from the fish table.
func roll_fish() -> FishData:
	var total := 0.0
	for f in fish_table:
		total += f.weight
	var r := randf() * total
	for f in fish_table:
		r -= f.weight
		if r <= 0.0:
			return f
	return fish_table.back()


func bucket_full() -> bool:
	return bucket.size() >= BUCKET_CAP


func add_fish(f: FishData) -> bool:
	if bucket_full():
		return false
	bucket.append(f)
	bucket_changed.emit(bucket)
	return true


func bucket_value() -> int:
	var total := 0
	for f in bucket:
		total += f.price
	return total


## Sells everything in the bucket. Returns the money earned.
func sell_all() -> int:
	var earned := bucket_value()
	bucket.clear()
	money += earned
	bucket_changed.emit(bucket)
	money_changed.emit(money)
	return earned
