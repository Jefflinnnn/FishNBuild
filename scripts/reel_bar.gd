extends Control
## Reel minigame: a marker sweeps across the bar; press Space while it's in the
## green zone. Harder fish = smaller zone + faster marker. One press decides it.

signal finished(success: bool)

const BAR_SIZE := Vector2(420, 34)
const TIME_LIMIT := 4.0

var _active := false
var _marker := 0.0     # 0..1
var _dir := 1.0
var _speed := 1.0      # bar widths per second
var _zone_start := 0.0
var _zone_size := 0.3
var _time_left := 0.0
var _flash := 0.0
var _flash_color := Color.WHITE


func _ready() -> void:
	custom_minimum_size = BAR_SIZE + Vector2(0, 40)
	visible = false


func start(difficulty: float) -> void:
	_zone_size = lerpf(0.32, 0.14, difficulty)
	_speed = lerpf(0.9, 1.8, difficulty)
	_zone_start = randf_range(0.15, 0.85 - _zone_size)
	_marker = 0.0
	_dir = 1.0
	_time_left = TIME_LIMIT
	_active = true
	visible = true


func press() -> void:
	if not _active:
		return
	var hit := _marker >= _zone_start and _marker <= _zone_start + _zone_size
	_finish(hit)


func _finish(success: bool) -> void:
	_active = false
	_flash = 0.35
	_flash_color = Color(0.4, 1, 0.5) if success else Color(1, 0.4, 0.4)
	finished.emit(success)


func _process(delta: float) -> void:
	if _active:
		_marker += _dir * _speed * delta
		if _marker >= 1.0 or _marker <= 0.0:
			_marker = clampf(_marker, 0.0, 1.0)
			_dir *= -1.0
		_time_left -= delta
		if _time_left <= 0.0:
			_finish(false)
	elif _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			visible = false
	queue_redraw()


func _draw() -> void:
	var origin := (size - BAR_SIZE) / 2.0 + Vector2(0, 20)
	var r := Rect2(origin, BAR_SIZE)
	draw_string(get_theme_default_font(), origin + Vector2(0, -10), "REEL!  Press Space in the green",
		HORIZONTAL_ALIGNMENT_CENTER, BAR_SIZE.x, 18)
	draw_rect(r.grow(4), Color(0, 0, 0, 0.6))
	draw_rect(r, Color("2d3b48"))
	draw_rect(Rect2(origin + Vector2(BAR_SIZE.x * _zone_start, 0), Vector2(BAR_SIZE.x * _zone_size, BAR_SIZE.y)),
		Color("6fcf7a"))
	var mx := origin.x + BAR_SIZE.x * _marker
	draw_rect(Rect2(mx - 3, origin.y - 6, 6, BAR_SIZE.y + 12), Color.WHITE)
	if _active:
		var t := _time_left / TIME_LIMIT
		draw_rect(Rect2(origin + Vector2(0, BAR_SIZE.y + 8), Vector2(BAR_SIZE.x * t, 4)), Color(1, 1, 1, 0.6))
	if _flash > 0.0:
		draw_rect(r, Color(_flash_color, _flash), false, 4.0)
