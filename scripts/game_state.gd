extends Node
## Autoload "Game": money, the fish bucket, and the fish table.
## Everything save/load will need later lives here.

signal money_changed(money: int)
signal bucket_changed(bucket: Array)

const FISH_DIR := "res://data/fish/"
const FURNITURE_DIR := "res://data/furniture/"
const BUCKET_CAP := 10
## Testing switch: true = building costs nothing. Set false once the shop/prices matter.
const FREE_BUILD := true

var money := 0
var bucket: Array[FishData] = []
var fish_table: Array[FishData] = []
## Sorted by hotbar order.
var furniture_table: Array[FurnitureData] = []


func _ready() -> void:
	for r in _load_dir(FISH_DIR):
		if r is FishData:
			fish_table.append(r)
	for r in _load_dir(FURNITURE_DIR):
		if r is FurnitureData:
			furniture_table.append(r)
	furniture_table.sort_custom(func(a, b): return a.order < b.order)
	if fish_table.is_empty():
		push_error("No fish found in %s" % FISH_DIR)


func _load_dir(dir: String) -> Array[Resource]:
	var out: Array[Resource] = []
	for file in ResourceLoader.list_directory(dir):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var r := load(dir + file)
			if r:
				out.append(r)
	return out


func can_afford(price: int) -> bool:
	return FREE_BUILD or money >= price


## Pays for an item. Returns false (and spends nothing) if you can't afford it.
func spend(price: int) -> bool:
	if FREE_BUILD:
		return true
	if money < price:
		return false
	money -= price
	money_changed.emit(money)
	return true


func refund(price: int) -> void:
	if FREE_BUILD:
		return
	money += price
	money_changed.emit(money)


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
