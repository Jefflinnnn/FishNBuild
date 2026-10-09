extends Node3D
## Square outline over the hovered tile. Green = valid action, red = not.

const OK := Color(0.4, 1.0, 0.5)
const BAD := Color(1.0, 0.35, 0.35)

var valid := true:
	set(v):
		if v != valid:
			valid = v
			_apply()

var _parts: Array[MeshInstance3D] = []
var _fill: MeshInstance3D


func _ready() -> void:
	var t := 0.05
	for spec in [[Vector3(1.0, 0.03, t), Vector3(0, 0, -0.5 + t / 2)], [Vector3(1.0, 0.03, t), Vector3(0, 0, 0.5 - t / 2)],
			[Vector3(t, 0.03, 1.0), Vector3(-0.5 + t / 2, 0, 0)], [Vector3(t, 0.03, 1.0), Vector3(0.5 - t / 2, 0, 0)]]:
		_parts.append(MeshKit.box(self, spec[0], OK, spec[1]))
	_fill = MeshKit.box(self, Vector3(0.96, 0.01, 0.96), Color(OK, 0.25))
	_apply()


func _apply() -> void:
	if _fill == null:
		return
	var c := OK if valid else BAD
	var line := StandardMaterial3D.new()
	line.albedo_color = c
	line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for p in _parts:
		p.material_override = line
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fill := StandardMaterial3D.new()
	fill.albedo_color = Color(c, 0.22)
	fill.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fill.material_override = fill
	_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
