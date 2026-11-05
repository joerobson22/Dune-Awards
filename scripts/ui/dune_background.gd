class_name DuneBackground
extends Control
## The night desert behind every slide: sky, two moons, layered dunes
## with a gold rim of light, and drifting sand. It stays put while
## slides change, so the room never flashes to black.

const GRAINS := 110

var _grains := []
var _time := 0.0
var _vignette: TextureRect


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 10191
	for i in GRAINS:
		_grains.append({
			"pos": Vector2(rng.randf() * 1920.0, rng.randf() * 1080.0),
			"speed": rng.randf_range(10.0, 42.0),
			"size": rng.randf_range(0.8, 2.4),
			"alpha": rng.randf_range(0.05, 0.28),
			"phase": rng.randf() * TAU,
		})
	_vignette = TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.62))
	g.add_point(0.55, Color(0, 0, 0, 0.08))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.42)
	t.fill_to = Vector2(1.18, 1.05)
	t.width = 256
	t.height = 144
	_vignette.texture = t
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.size = size
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)


func _process(delta: float) -> void:
	_time += delta
	for gr in _grains:
		gr["pos"].x -= gr["speed"] * delta
		gr["pos"].y += sin(_time * 0.6 + gr["phase"]) * 6.0 * delta
		if gr["pos"].x < -4.0:
			gr["pos"].x = size.x + 4.0
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Sky: near-black at the top warming to burnt umber at the horizon.
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Color("070504"), Color("0b0705"), Color("26170c"), Color("221509")]))
	# Horizon haze.
	# Horizon haze: a soft band that swells and fades, with no hard edge.
	for i in 40:
		var y := h * 0.58 + i * 6.0
		var a := sin(PI * i / 40.0) * 0.07
		draw_rect(Rect2(0, y, w, 6.0), Color(0.55, 0.33, 0.14, a))
	# Two moons, low and faint.
	_moon(Vector2(w * 0.84, h * 0.17), 46.0, 0.11)
	_moon(Vector2(w * 0.9, h * 0.26), 20.0, 0.08)
	# Three dune ridges, back to front.
	_dune(h * 0.80, 34.0, 0.0011, 0.06, Color("1c120a"), 0.10)
	_dune(h * 0.86, 26.0, 0.0017, -0.04, Color("21150b"), 0.16)
	_dune(h * 0.93, 18.0, 0.0024, 0.03, Color("281a0e"), 0.22)
	# Drifting sand.
	for gr in _grains:
		draw_circle(gr["pos"], gr["size"], Color(Config.SAND, gr["alpha"]), true, -1.0, true)


func _moon(c: Vector2, r: float, a: float) -> void:
	for i in 6:
		draw_circle(c, r * (1.0 + i * 0.35), Color(Config.SAND, a * 0.06 / (i + 1)), true, -1.0, true)
	draw_circle(c, r, Color(Config.SAND, a), true, -1.0, true)


func _dune(base: float, amp: float, freq: float, drift: float, colour: Color, rim: float) -> void:
	var w := size.x
	var pts := PackedVector2Array()
	var crest := PackedVector2Array()
	var shift := _time * drift * 60.0
	var x := 0.0
	while x <= w + 24.0:
		var y := base - amp * (sin((x + shift) * freq) * 0.7 + sin((x + shift) * freq * 2.3 + 1.3) * 0.3)
		crest.append(Vector2(x, y))
		x += 24.0
	pts.append_array(crest)
	pts.append(Vector2(w + 24.0, size.y))
	pts.append(Vector2(0, size.y))
	draw_colored_polygon(pts, colour)
	draw_polyline(crest, Color(Config.GOLD, rim), 1.5, true)
