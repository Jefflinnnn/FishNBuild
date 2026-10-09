class_name MeshKit
extends RefCounted
## Tiny helpers for building placeholder models out of primitive meshes.
## Materials are cached per color so 256 tiles share a handful of materials.

static var _mats := {}


static func mat(color: Color, roughness := 0.85, emission := 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [color.to_html(), roughness, emission]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		if color.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if emission > 0.0:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = emission
		_mats[key] = m
	return _mats[key]


static func _add(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, emission := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, 0.85, emission)
	mi.position = pos
	parent.add_child(mi)
	return mi


## Box whose BOTTOM sits at pos.y (easier to stack than center-based boxes).
static func box(parent: Node3D, size: Vector3, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _add(parent, m, color, pos + Vector3(0, size.y / 2.0, 0))


static func cylinder(parent: Node3D, radius: float, height: float, color: Color, pos := Vector3.ZERO, top_radius := -1.0) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = radius if top_radius < 0.0 else top_radius
	m.height = height
	m.radial_segments = 20
	return _add(parent, m, color, pos + Vector3(0, height / 2.0, 0))


static func sphere(parent: Node3D, radius: float, color: Color, pos := Vector3.ZERO, emission := 0.0) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 20
	m.rings = 10
	return _add(parent, m, color, pos, emission)


static func capsule(parent: Node3D, radius: float, height: float, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	return _add(parent, m, color, pos + Vector3(0, height / 2.0, 0))


## Loads a .glb/.tscn model if it exists, else returns null (caller draws a placeholder).
static func load_model(path: String) -> Node3D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res := load(path)
	if res is PackedScene:
		return (res as PackedScene).instantiate() as Node3D
	return null
