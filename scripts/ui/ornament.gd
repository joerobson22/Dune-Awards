class_name Ornament
extends Control
## A gold rule with a diamond: the divider under every title.
## `centred` puts the diamond in the middle; otherwise it sits at the left.

var centred := false
var colour := Config.GOLD


func _init(width := 360.0, is_centred := false) -> void:
	custom_minimum_size = Vector2(width, 14)
	size = custom_minimum_size
	centred = is_centred
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var y := size.y * 0.5
	var c := size.x * 0.5 if centred else 7.0
	var line := Color(colour, 0.55)
	_diamond(Vector2(c, y), 6.0)
	_diamond(Vector2(c + 20, y), 2.5)
	draw_line(Vector2(c + 30, y), Vector2(size.x, y), line, 1.0, true)
	if centred:
		_diamond(Vector2(c - 20, y), 2.5)
		draw_line(Vector2(0, y), Vector2(c - 30, y), line, 1.0, true)


func _diamond(p: Vector2, r: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), colour)
