extends Node
## Autoload "Sfx". Sfx.play("cast") plays res://audio/sfx_cast.ogg if it exists,
## and silently does nothing until Tiffany's sounds land.

const DIR := "res://audio/"

var _cache := {}


func play(sound: String) -> void:
	var path := DIR + "sfx_" + sound + ".ogg"
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	var stream: AudioStream = _cache[path]
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
