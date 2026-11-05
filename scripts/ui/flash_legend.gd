class_name FlashLegend
extends Control
## A one-line key: coloured dot + label for each entry.
##   FlashLegend.new([{"colour": Color.GOLD, "text": "Streak"}, ...])

var items: Array = []


func _init(entries: Array) -> void:
	items = entries
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var f := UI.font(UI.Face.DISPLAY, 2)
	var x := 0.0
	var y := size.y * 0.5
	for it in items:
		draw_circle(Vector2(x + 6, y), 6.0, it["colour"], true, -1.0, true)
		var t: String = it["text"].to_upper()
		draw_string(f, Vector2(x + 20, y + 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Config.SAND_DIM)
		x += 20 + f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 24
