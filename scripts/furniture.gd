class_name Furniture
extends Node3D
## A placed (or ghost) piece of furniture standing on one tile. Origin = tile's
## top center. Builds placeholder primitives until its .glb model exists.

const GHOST_OK := Color(1, 1, 1)
const GHOST_BAD := Color(1, 0.3, 0.3)

var data: FurnitureData
var cell := Vector2i.ZERO
## Quarter turns (0-3); R rotates by 90 degrees.
var turns := 0:
	set(v):
		turns = posmod(v, 4)
		rotation.y = turns * PI / 2.0

var _ghost := false
var _ghost_valid := true
var _bad_overlay: StandardMaterial3D


func setup(d: FurnitureData, ghost := false) -> void:
	data = d
	_ghost = ghost
	for c in get_children():
		c.queue_free()
	var m := MeshKit.load_model(d.model_path)
	if m:
		# Models are made facing Blender's Front view, which imports facing +Z.
		m.rotation.y = PI
		add_child(m)
	else:
		_build_placeholder()
	if d.shape == "lamp":
		_add_lamp_light()
	if ghost:
		_apply_ghost()


## Ghost look: see-through, red when the spot is invalid.
func set_ghost(on: bool, valid := true) -> void:
	_ghost = on
	_ghost_valid = valid
	_apply_ghost()


func _apply_ghost() -> void:
	if _bad_overlay == null:
		_bad_overlay = StandardMaterial3D.new()
		_bad_overlay.albedo_color = Color(1, 0.2, 0.2, 0.55)
		_bad_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_bad_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for g in _geometry(self):
		g.transparency = 0.45 if _ghost else 0.0
		g.material_overlay = _bad_overlay if (_ghost and not _ghost_valid) else null
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if _ghost else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for l in find_children("*", "Light3D", true, false):
		(l as Light3D).visible = not _ghost


func _geometry(n: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	for c in n.find_children("*", "GeometryInstance3D", true, false):
		out.append(c)
	return out


## The game adds the light, so a lamp model only needs an emissive bulb at ~1.6 m.
func _add_lamp_light() -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.55)
	light.light_energy = 0.9
	light.omni_range = 3.0
	light.position = Vector3(0, 1.45, 0)
	add_child(light)


func _build_placeholder() -> void:
	var c := data.color
	match data.shape:
		"dock":
			for i in 4:
				MeshKit.box(self, Vector3(0.23, 0.08, 1.0), c.darkened(0.06 * (i % 2)), Vector3(-0.375 + i * 0.25, -0.08, 0))
		"chair":
			for p in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
				MeshKit.box(self, Vector3(0.05, 0.3, 0.05), c.darkened(0.35), Vector3(p.x, 0, p.y))
			MeshKit.box(self, Vector3(0.46, 0.07, 0.46), c, Vector3(0, 0.3, 0))
			MeshKit.box(self, Vector3(0.46, 0.45, 0.06), c.darkened(0.12), Vector3(0, 0.37, 0.2))
		"desk":
			for p in [Vector2(-0.38, -0.25), Vector2(0.38, -0.25), Vector2(-0.38, 0.25), Vector2(0.38, 0.25)]:
				MeshKit.box(self, Vector3(0.07, 0.55, 0.07), c.darkened(0.3), Vector3(p.x, 0, p.y))
			MeshKit.box(self, Vector3(0.9, 0.06, 0.62), c, Vector3(0, 0.55, 0))
			MeshKit.box(self, Vector3(0.3, 0.16, 0.5), c.darkened(0.15), Vector3(0.24, 0.39, 0))  # drawer
			MeshKit.box(self, Vector3(0.22, 0.03, 0.3), Color("efeae0"), Vector3(-0.15, 0.61, 0))  # paper
			MeshKit.cylinder(self, 0.04, 0.09, Color("4a6fa5"), Vector3(-0.32, 0.61, -0.15))  # pen cup
		"coffee":
			MeshKit.cylinder(self, 0.06, 0.38, Color("6b4a35"), Vector3.ZERO)
			MeshKit.cylinder(self, 0.18, 0.02, Color("6b4a35"), Vector3.ZERO)
			MeshKit.cylinder(self, 0.3, 0.05, Color("8a5a3c"), Vector3(0, 0.38, 0))
			MeshKit.cylinder(self, 0.06, 0.11, c, Vector3(0.05, 0.43, 0))  # cup
			MeshKit.cylinder(self, 0.05, 0.01, Color("5a3420"), Vector3(0.05, 0.54, 0))  # coffee
			MeshKit.cylinder(self, 0.1, 0.01, c.darkened(0.1), Vector3(0.05, 0.43, 0))  # saucer
		"lamp":
			MeshKit.cylinder(self, 0.14, 0.05, Color("4a4a52"), Vector3.ZERO)
			MeshKit.cylinder(self, 0.03, 1.5, Color("4a4a52"), Vector3.ZERO)
			MeshKit.sphere(self, 0.13, c, Vector3(0, 1.6, 0), 3.0)
			MeshKit.cylinder(self, 0.2, 0.12, Color("3a3a42"), Vector3(0, 1.66, 0), 0.08)
		"shrub":
			for s in [[Vector3(-0.15, 0.22, 0.05), 0.26], [Vector3(0.17, 0.2, -0.05), 0.24], [Vector3(0, 0.4, 0), 0.25],
					[Vector3(0.02, 0.18, 0.18), 0.2], [Vector3(-0.05, 0.2, -0.2), 0.2]]:
				MeshKit.sphere(self, s[1], c.darkened(0.08 if s[0].y > 0.3 else 0.0), s[0])
			MeshKit.sphere(self, 0.06, Color("f3a6c0"), Vector3(-0.12, 0.55, 0.12))
			MeshKit.sphere(self, 0.05, Color("fff2a8"), Vector3(0.22, 0.38, 0.12))
			MeshKit.sphere(self, 0.05, Color("f3a6c0"), Vector3(0.1, 0.3, 0.32))
		_:
			MeshKit.box(self, Vector3(0.6, 0.6, 0.6), c)
