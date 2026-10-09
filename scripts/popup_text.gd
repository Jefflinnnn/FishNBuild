class_name PopupText
extends RefCounted
## Floating text that rises and fades out ("+$20", "Bluegill!").

static func spawn(parent: Node, at: Vector2, text: String, color := Color.WHITE, size := 26) -> void:
	var p := Node2D.new()
	p.z_index = 100
	parent.add_child(p)
	p.global_position = at
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(400, 40)
	l.position = Vector2(-200, -20)
	p.add_child(l)
	var tw := p.create_tween().set_parallel()
	tw.tween_property(p, "position:y", p.position.y - 60, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(p, "modulate:a", 0.0, 0.5).set_delay(0.8)
	tw.chain().tween_callback(p.queue_free)
