class_name AllianceEmblem
extends Control
## The badge for one alliance. If res://assets/alliances/<key>.png exists
## it is shown; otherwise a gold emblem is drawn:
##   Emperor: a crown · Spacing Guild: a planet in orbit
##   Bene Gesserit: the watching eye · Fremen: the maw of a sandworm

var key := ""
var tint := Config.GOLD
var _tex: Texture2D


func _init(alliance_key: String, side := 180.0) -> void:
	key = alliance_key
	custom_minimum_size = Vector2(side, side)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := "res://assets/alliances/%s.png" % key
	if ResourceLoader.exists(path):
		_tex = load(path)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	if _tex:
		draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false)
		return
	var gold := Config.GOLD
	var line := Color(gold, 0.9)
	# A disc in the alliance colour inside a double gold ring.
	draw_circle(c, r - 4, Color(tint, 0.16), true, -1.0, true)
	draw_circle(c, r - 4, Color(gold, 0.7), false, 2.0, true)
	draw_circle(c, r - 12, Color(gold, 0.35), false, 1.0, true)
	var s := r * 0.55  # emblem scale
	match key:
		"emperor":
			var base_y := c.y + s * 0.45
			var pts := PackedVector2Array([
				Vector2(c.x - s, base_y), Vector2(c.x - s, c.y - s * 0.35),
				Vector2(c.x - s * 0.5, c.y + s * 0.05), Vector2(c.x, c.y - s * 0.75),
				Vector2(c.x + s * 0.5, c.y + s * 0.05), Vector2(c.x + s, c.y - s * 0.35),
				Vector2(c.x + s, base_y)])
			draw_colored_polygon(pts, Color(gold, 0.85))
			draw_rect(Rect2(c.x - s, base_y + s * 0.12, s * 2, s * 0.22), Color(gold, 0.85))
			for x in [-s, 0.0, s]:
				var tip_y := c.y - s * 0.75 if x == 0.0 else c.y - s * 0.35
				draw_circle(Vector2(c.x + x, tip_y - s * 0.12), s * 0.11, gold, true, -1.0, true)
		"spacing_guild":
			draw_circle(c, s * 0.55, Color(gold, 0.85), true, -1.0, true)
			_ellipse(c, Vector2(s * 1.05, s * 0.32), -0.42, line, 3.0)
			draw_circle(c + (Vector2(cos(-2.1) * s * 1.05, sin(-2.1) * s * 0.32)).rotated(-0.42), s * 0.13, gold, true, -1.0, true)
		"bene_gesserit":
			var eye := PackedVector2Array()
			for i in 25:
				var t := PI * i / 24.0
				eye.append(c + Vector2(-s * 1.05 + s * 2.1 * i / 24.0, -sin(t) * s * 0.62))
			for i in 25:
				var t := PI * i / 24.0
				eye.append(c + Vector2(s * 1.05 - s * 2.1 * i / 24.0, sin(t) * s * 0.62))
			draw_colored_polygon(eye, Color(gold, 0.85))
			draw_circle(c, s * 0.42, Config.INK, true, -1.0, true)
			draw_circle(c, s * 0.42, gold, false, 2.0, true)
			draw_circle(c, s * 0.17, gold, true, -1.0, true)
		"fremen":
			draw_circle(c, s * 0.95, Color(gold, 0.85), true, -1.0, true)
			draw_circle(c, s * 0.62, Config.INK, true, -1.0, true)
			var teeth := 14
			for i in teeth:
				var a := TAU * i / teeth
				var a1 := a - PI / teeth * 0.6
				var a2 := a + PI / teeth * 0.6
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(cos(a1), sin(a1)) * s * 0.64,
					c + Vector2(cos(a2), sin(a2)) * s * 0.64,
					c + Vector2(cos(a), sin(a)) * s * 0.3]), Color(gold, 0.85))
			draw_circle(c, s * 0.16, Color(gold, 0.5), false, 1.5, true)
		_:
			draw_circle(c, s * 0.5, gold, false, 3.0, true)


func _ellipse(c: Vector2, radii: Vector2, angle: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i in 49:
		var t := TAU * i / 48.0
		pts.append(c + Vector2(cos(t) * radii.x, sin(t) * radii.y).rotated(angle))
	draw_polyline(pts, col, width, true)
