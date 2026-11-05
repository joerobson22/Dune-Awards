class_name RaceChart
extends Control
## A live line chart: one line per player, drawn game by game as
## `progress` moves from 0 to the number of games. Emits game_reached
## each time a new game is crossed so the slide can react, and draws
## coloured pulses where flash() is called.

signal game_reached(game_index: int)

const PAD_L := 72.0
const PAD_R := 236.0
const PAD_T := 64.0
const PAD_B := 58.0
const FLASH_LIFE := 1.7

var players: Array = []
var series := {}          # player -> Array of values, index 0 = before game 1
var colours := {}
var names := {}
var spans: Array = []     # [{name, first, last}] from GameData.expansion_spans()
var n_games := 1
var y_max := 10.0
var y_step := 2.0
var axis_title := ""
var progress := 0.0: set = set_progress

var _crossed := 0
var _flashes := []
var _font_display: Font
var _font_serif: Font
var _font_num: Font
var _font_italic: Font
var _panel_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font_display = UI.font(UI.Face.DISPLAY, 2)
	_font_serif = UI.font(UI.Face.SERIF_BOLD)
	_font_num = UI.font(UI.Face.NUMBER)
	_font_italic = UI.font(UI.Face.ITALIC)
	_panel_style = UI.panel_style()


## Picks a round axis maximum and step for the largest value.
func fit_axis(max_value: float) -> void:
	var raw := max_value / 5.0
	var mag := pow(10.0, floor(log(raw) / log(10.0)))
	for m in [1.0, 2.0, 2.5, 5.0, 10.0]:
		if m * mag >= raw:
			y_step = m * mag
			break
	y_max = ceil(max_value / y_step) * y_step
	if y_max <= max_value:
		y_max += y_step


func set_progress(v: float) -> void:
	progress = clampf(v, 0.0, float(n_games))
	var whole := int(floor(progress + 0.0001))
	while _crossed < whole:
		_crossed += 1
		game_reached.emit(_crossed)
	queue_redraw()


func reset() -> void:
	_crossed = 0
	_flashes.clear()
	progress = 0.0


func clear_flashes() -> void:
	_flashes.clear()
	queue_redraw()


## Pulse a ring on a player's line at the latest game, with a caption.
func flash(player: String, colour: Color, caption: String) -> void:
	var stack := 0
	for f in _flashes:
		if f["game"] == _crossed and f["player"] == player:
			stack += 1
		elif f["player"] == player and not f.has("gone"):
			f["gone"] = _now()  # an older caption for this line fades out
	_flashes.append({"player": player, "game": _crossed, "colour": colour,
		"caption": caption, "born": _now(), "stack": stack})


func plot_rect() -> Rect2:
	return Rect2(PAD_L, PAD_T, size.x - PAD_L - PAD_R, size.y - PAD_T - PAD_B)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(_d: float) -> void:
	if _flashes.is_empty():
		return
	var t := _now()
	_flashes = _flashes.filter(func(f): return t - f["born"] < FLASH_LIFE)
	queue_redraw()


func _point(game: float, value: float) -> Vector2:
	var r := plot_rect()
	return Vector2(r.position.x + r.size.x * game / float(n_games),
		r.end.y - r.size.y * value / y_max)


func _value_at(player: String, p: float) -> float:
	var s: Array = series[player]
	var i := int(floor(p))
	if i >= s.size() - 1:
		return s[-1]
	return lerpf(s[i], s[i + 1], p - i)


func _draw() -> void:
	draw_style_box(_panel_style, Rect2(Vector2.ZERO, size))
	var r := plot_rect()

	# Expansion bands, with their names along the top.
	for i in spans.size():
		var s: Dictionary = spans[i]
		var x0 := _point(s["first"] - 1, 0).x
		var x1 := _point(s["last"], 0).x
		if i % 2 == 1:
			draw_rect(Rect2(x0, r.position.y, x1 - x0, r.size.y), Color(Config.GOLD, 0.035))
		if i > 0:
			_dashed_v(x0, r.position.y - 26, r.end.y, Color(Config.GOLD, 0.35))
		var text: String = s["name"]
		var fs := 24
		while fs > 14 and _font_italic.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > x1 - x0 - 14:
			fs -= 1
		draw_string(_font_italic, Vector2(x0 + 9, r.position.y - 14), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Config.GOLD)

	# Horizontal gridlines and value labels.
	var v := 0.0
	while v <= y_max + 0.001:
		var y := _point(0, v).y
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y),
			Color(Config.SAND, 0.16 if v == 0.0 else 0.06), 1.0)
		draw_string(_font_num, Vector2(0, y + 7), _fmt(v), HORIZONTAL_ALIGNMENT_RIGHT,
			r.position.x - 14, 18, Config.SAND_DIM)
		v += y_step

	# Game numbers along the bottom.
	var every := 5 if n_games > 20 else (2 if n_games > 8 else 1)
	for g in range(every, n_games + 1, every):
		var x := _point(g, 0).x
		draw_line(Vector2(x, r.end.y), Vector2(x, r.end.y + 6), Color(Config.SAND, 0.3), 1.0)
		draw_string(_font_num, Vector2(x - 30, r.end.y + 28), str(g), HORIZONTAL_ALIGNMENT_CENTER,
			60, 17, Config.SAND_DIM)
	draw_string(_font_display, Vector2(r.position.x, r.end.y + 48), "GAME", HORIZONTAL_ALIGNMENT_LEFT,
		-1, 11, Config.SAND_FAINT)
	if axis_title != "":
		draw_string(_font_display, Vector2(r.position.x, r.position.y - 46), axis_title.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Config.SAND_FAINT)

	# Lines, drawn up to the current progress.
	var heads := []
	for p in players:
		var pts := PackedVector2Array()
		var s: Array = series[p]
		var last_whole := int(floor(progress))
		for i in range(0, mini(last_whole, n_games) + 1):
			pts.append(_point(i, s[i]))
		if progress > last_whole and last_whole < n_games:
			pts.append(_point(progress, _value_at(p, progress)))
		if pts.size() >= 2:
			draw_polyline(pts, Color(colours[p], 0.14), 9.0, true)
			draw_polyline(pts, colours[p], 3.0, true)
		var head := _point(progress, _value_at(p, progress))
		draw_circle(head, 5.0, colours[p], true, -1.0, true)
		draw_circle(head, 5.0, Config.NIGHT, false, 1.5, true)
		# The number shows completed games only, matching the leaderboard.
		heads.append({"player": p, "pos": head, "value": s[mini(last_whole, n_games)]})

	# Name labels at the head of each line, nudged apart so none overlap.
	heads.sort_custom(func(a, b): return a["pos"].y < b["pos"].y)
	var gap := 30.0
	var ys := []
	for i in heads.size():
		var y: float = heads[i]["pos"].y
		if i > 0:
			y = maxf(y, ys[i - 1] + gap)
		ys.append(y)
	var overflow: float = ys[-1] - (r.end.y - 4.0) if not ys.is_empty() else 0.0
	if overflow > 0.0:
		for i in ys.size():
			ys[i] -= overflow
		for i in range(ys.size() - 2, -1, -1):
			ys[i] = minf(ys[i], ys[i + 1] - gap)
	for i in heads.size():
		var h: Dictionary = heads[i]
		var lx: float = h["pos"].x + 14.0
		var ly: float = ys[i]
		if absf(ly - h["pos"].y) > 2.0:
			draw_line(h["pos"] + Vector2(6, 0), Vector2(lx - 3, ly), Color(colours[h["player"]], 0.5), 1.0, true)
		var nm: String = names[h["player"]]
		var val := _fmt(round(h["value"]))
		var nm_w := _font_serif.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		var val_w := _font_num.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		# Keep the label inside the panel when a line is near the right edge.
		lx = minf(lx, size.x - 14.0 - nm_w - 10.0 - val_w)
		draw_string(_font_serif, Vector2(lx, ly + 8), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, colours[h["player"]])
		draw_string(_font_num, Vector2(lx + nm_w + 10.0, ly + 8), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Config.SAND)

	# Flashes: an expanding ring and a rising caption.
	var t := _now()
	for f in _flashes:
		var age: float = (t - f["born"]) / FLASH_LIFE
		var pos := _point(f["game"], series[f["player"]][f["game"]])
		var col: Color = f["colour"]
		var ring := ease(clampf(age * 1.4, 0.0, 1.0), 0.4)
		draw_circle(pos, 9.0 + 34.0 * ring, Color(col, 0.9 * (1.0 - ring)), false, 3.0, true)
		draw_circle(pos, 9.0, Color(col, 1.0 - age), true, -1.0, true)
		var cap: String = f["caption"]
		var fs := 18
		var cw := _font_num.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		# Caption sits up and to the left of the point, clear of the
		# name label that trails to the right of each line.
		var cx := clampf(pos.x - cw - 26.0, r.position.x + 12.0, size.x - cw - 12.0)
		var cy: float = pos.y - 22.0 - 34.0 * f["stack"] - 10.0 * age
		cy = maxf(cy, r.position.y + 20.0)
		var a := 1.0 - smoothstep(0.65, 1.0, age)
		if f.has("gone"):
			a *= 1.0 - clampf((t - f["gone"]) / 0.25, 0.0, 1.0)
		var pill := Rect2(cx - 12, cy - 20, cw + 24, 28)
		draw_rect(pill, Color(Config.NIGHT, 0.88 * a))
		draw_rect(pill, Color(col, 0.75 * a), false, 1.0)
		draw_string(_font_num, Vector2(cx, cy), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col, a))


func _dashed_v(x: float, y0: float, y1: float, col: Color) -> void:
	var y := y0
	while y < y1:
		draw_line(Vector2(x, y), Vector2(x, minf(y + 5.0, y1)), col, 1.0)
		y += 10.0


func _fmt(v: float) -> String:
	return str(int(round(v)))
