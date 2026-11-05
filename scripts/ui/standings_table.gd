class_name StandingsTable
extends Control
## A live leaderboard that sits beside a RaceChart. Rows slide into
## order as values change, and any cell can flash a colour.
##
## columns: [{key, header, width}] — each cell shows a big value and an
## optional small caption beneath it (set_cell(player, key, value, caption)).

const HEADER_H := 46.0
var row_h := 84.0
const NAME_X := 26.0

var columns: Array = []
var _rows := {}      # player -> {node, cells: {key -> {value, caption, glow}}}
var _order: Array = []
var _moves := {}     # player -> running reorder tween


func setup(data: GameData, cols: Array) -> void:
	columns = cols
	row_h = minf(110.0, (size.y - HEADER_H - 18.0) / maxf(1.0, data.players.size()))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.panel(Rect2(Vector2.ZERO, size)))
	# Column headers: right-aligned columns, the name column left-aligned.
	var head_y := 0.0
	var name_head := UI.eyebrow("Player", 12, Config.SAND_DIM)
	name_head.position = Vector2(NAME_X, head_y)
	name_head.size = Vector2(160, HEADER_H)
	add_child(name_head)
	for c in columns:
		var l := UI.eyebrow(c["header"], 12, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
		l.position = Vector2(_col_x(c["key"]), head_y)
		l.size = Vector2(c["width"] - 18, HEADER_H)
		add_child(l)
	var rule := ColorRect.new()
	rule.color = Color(Config.GOLD, 0.3)
	rule.position = Vector2(NAME_X, HEADER_H)
	rule.size = Vector2(size.x - NAME_X * 2, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
	for p in data.players:
		_order.append(p)
		_rows[p] = _make_row(data, p)
	_place_rows(false)


func _col_x(key: String) -> float:
	var x := size.x - NAME_X
	for i in range(columns.size() - 1, -1, -1):
		x -= columns[i]["width"]
		if columns[i]["key"] == key:
			return x
	return x


func _make_row(data: GameData, p: String) -> Dictionary:
	var row := Control.new()
	row.size = Vector2(size.x, row_h)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var swatch := ColorRect.new()
	swatch.color = data.colour_of(p)
	swatch.position = Vector2(NAME_X, row_h * 0.5 - 22)
	swatch.size = Vector2(4, 44)
	row.add_child(swatch)
	var name_l := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, 32, Config.SAND)
	name_l.position = Vector2(NAME_X + 18, 0)
	name_l.size = Vector2(_col_x(columns[0]["key"]) - NAME_X - 24, row_h)
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_l)
	var cells := {}
	for c in columns:
		var x := _col_x(c["key"])
		var glow := Panel.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 1, 1, 0)
		st.set_corner_radius_all(2)
		glow.add_theme_stylebox_override("panel", st)
		glow.position = Vector2(x + 8, row_h * 0.5 - 38)
		glow.size = Vector2(c["width"] - 14, 76)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(glow)
		var val := UI.label("0", UI.Face.NUMBER, 34, Config.SAND, HORIZONTAL_ALIGNMENT_RIGHT)
		val.position = Vector2(x, row_h * 0.5 - 34)
		val.size = Vector2(c["width"] - 18, 40)
		row.add_child(val)
		var cap := RichTextLabel.new()
		cap.bbcode_enabled = true
		cap.fit_content = false
		cap.scroll_active = false
		cap.autowrap_mode = TextServer.AUTOWRAP_OFF
		cap.position = Vector2(x, row_h * 0.5 + 6)
		cap.size = Vector2(c["width"] - 18, 28)
		cap.add_theme_font_override("normal_font", UI.font(UI.Face.ITALIC))
		cap.add_theme_font_size_override("normal_font_size", 19)
		cap.add_theme_color_override("default_color", Config.SAND_DIM)
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cap)
		var dots := Dots.new()
		dots.position = Vector2(x, row_h * 0.5 + 12)
		dots.size = Vector2(c["width"] - 18, 16)
		row.add_child(dots)
		cells[c["key"]] = {"value": val, "caption": cap, "glow": glow, "style": st, "dots": dots}
	return {"node": row, "cells": cells}


func set_cell(player: String, key: String, value: String, caption := "") -> void:
	var cell: Dictionary = _rows[player]["cells"][key]
	cell["value"].text = value
	cell["caption"].text = "[right]%s[/right]" % caption


## Shows a row of coloured dots under a cell's value (e.g. how each
## tie-break was won) in place of the caption text.
func set_dots(player: String, key: String, dot_colours: Array) -> void:
	var dots: Dots = _rows[player]["cells"][key]["dots"]
	dots.colours = dot_colours
	dots.queue_redraw()


## Briefly lights a cell and its number in a colour.
func flash_cell(player: String, key: String, colour: Color) -> void:
	var cell: Dictionary = _rows[player]["cells"][key]
	var st: StyleBoxFlat = cell["style"]
	var val: Label = cell["value"]
	var tw := create_tween().set_parallel()
	st.bg_color = Color(colour, 0.32)
	st.border_color = colour
	st.set_border_width_all(1)
	tw.tween_property(st, "bg_color", Color(colour, 0.0), 1.3).set_ease(Tween.EASE_IN)
	tw.tween_property(st, "border_color", Color(colour, 0.0), 1.3).set_ease(Tween.EASE_IN)
	val.add_theme_color_override("font_color", colour)
	tw.tween_method(func(c): val.add_theme_color_override("font_color", c), colour, Config.SAND, 1.3)


## Reorders rows by the given values (highest first). Equal values keep
## their current order so rows do not jitter.
func sort_by(values: Dictionary, animate := true) -> void:
	var current := _order.duplicate()
	_order.sort_custom(func(a, b):
		if values[a] != values[b]:
			return values[a] > values[b]
		return current.find(a) < current.find(b))
	_place_rows(animate)


func _place_rows(animate: bool) -> void:
	for i in _order.size():
		var p: String = _order[i]
		var node: Control = _rows[p]["node"]
		var target := Vector2(0, HEADER_H + 8 + i * row_h)
		if _moves.has(p) and _moves[p].is_valid():
			_moves[p].kill()
		if animate and node.position != target:
			_moves[p] = create_tween()
			_moves[p].tween_property(node, "position", target, 0.45) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			node.position = target



class Dots extends Control:
	var colours: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var x := size.x - 6.0
		for i in range(colours.size() - 1, -1, -1):
			draw_circle(Vector2(x, size.y * 0.5), 5.0, colours[i], true, -1.0, true)
			x -= 15.0
