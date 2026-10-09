class_name PopupText
extends RefCounted
## Floating 3D text that rises and fades out ("+$20", "Bluegill!").

static func spawn(parent: Node, at: Vector3, text: String, color := Color.WHITE, size := 64) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 14
	l.modulate = color
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.006
	parent.add_child(l)
	l.global_position = at
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y + 0.8, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.8)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.5).set_delay(0.8)
	tw.chain().tween_callback(l.queue_free)
