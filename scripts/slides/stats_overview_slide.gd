class_name StatsOverviewSlide
extends Slide
## The stats overview: headline numbers, the wins leaderboard (filter it
## by expansion), wins by leader, and every game on record, newest first.
## "Add new game" records a result in data/games.csv. The show then
## reloads, so every slide in the ceremony includes the new game.
## Press S from any slide to jump here, and S again to go back.

const STRIP_H := 112.0
const GAP := 24.0
const BUTTON_Y := 960.0
const BUTTON_H := 44.0
const WINS_W := 440.0
const LEADERS_W := 360.0
const PAD := 28.0
## Inside each panel: the column headers, then the rows below them.
const COLS_Y := 132.0
const BODY_Y := 172.0
const RECORD_ROW_H := 64.0

## Expansion shown in the wins leaderboard ("" = every game). Kept when
## the slide is rebuilt, so adding a game does not reset it.
var wins_filter := ""
## Set before a rebuild to light up a game that was just added.
var added_game := 0
var added_message := ""

var _wins_body: Control
var _dialog: AddGameDialog
var _toast: Label


func build() -> void:
	stage.theme = UI.form_theme()
	var top := add_header("Stats overview", "The Imperial Record",
		"Every game on record, and room for the next", 48.0) + GAP
	_build_strip(Rect2(MARGIN, top, W - MARGIN * 2, STRIP_H))
	var py := top + STRIP_H + GAP
	var ph := BUTTON_Y - 18.0 - py
	var record_w := W - MARGIN * 2 - WINS_W - LEADERS_W - GAP * 2
	_build_wins(Rect2(MARGIN, py, WINS_W, ph))
	_build_leaders(Rect2(MARGIN + WINS_W + GAP, py, LEADERS_W, ph))
	_build_record(Rect2(MARGIN + WINS_W + LEADERS_W + GAP * 2, py, record_w, ph))
	_build_button()
	added_game = 0
	added_message = ""


func captures_input(event: InputEvent) -> bool:
	if is_instance_valid(_dialog):
		return true
	# Clicks here are for the filter, the scroll lists and the button.
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT


# ── Headline strip ───────────────────────────────────────────────────

func _build_strip(rect: Rect2) -> void:
	var strip := UI.panel(rect, UI.panel_style(Config.GOLD, 0.22, 0.8))
	add(strip)
	var big := data.biggest_finish()
	var ranking := data.rank(data.wins(), data.total_vp())
	var top_wins: int = ranking[0]["value"]
	var leaders := ranking.filter(func(r): return r["rank"] == 1)
	var items := [
		{"label": "Total games", "value": str(data.games.size()),
			"note": "across %s" % UI.plural(data.expansion_spans().size(), "expansion")},
		{"label": "Biggest VP finish", "value": str(big["vp"]),
			"note": "%s as %s, game %d" % [data.name_of(big["player"]), big["leader"], big["game"]],
			"colours": [data.colour_of(big["player"])]},
		{"label": "Most wins", "value": str(top_wins),
			"note": "%s, %d%% of games" % [data.winners_text(ranking),
				roundi(100.0 * top_wins / maxf(1, data.games.size()))],
			"colours": leaders.map(func(r): return data.colour_of(r["player"]))},
	]
	var w := rect.size.x / items.size()
	for i in items.size():
		var it: Dictionary = items[i]
		var x := i * w + 36.0
		if i > 0:
			var div := ColorRect.new()
			div.color = Color(Config.GOLD, 0.2)
			div.position = Vector2(i * w, 22)
			div.size = Vector2(1, rect.size.y - 44)
			div.mouse_filter = Control.MOUSE_FILTER_IGNORE
			strip.add_child(div)
		var e := UI.eyebrow(it["label"], 12, Config.SAND_DIM)
		e.position = Vector2(x, 20)
		e.size = Vector2(w - 72, 20)
		strip.add_child(e)
		var v := UI.label(it["value"], UI.Face.NUMBER, 44, Config.GOLD_BRIGHT)
		var vw := UI.font(UI.Face.NUMBER).get_string_size(it["value"], HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
		v.position = Vector2(x - 2, 44)
		v.size = Vector2(vw + 4, 52)
		strip.add_child(v)
		var nx := x + vw + 18.0
		var cols: Array = it.get("colours", [])
		for j in cols.size():
			var bar := ColorRect.new()
			bar.color = cols[j]
			bar.position = Vector2(nx + j * 7.0, 58)
			bar.size = Vector2(3, 26)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			strip.add_child(bar)
		if not cols.is_empty():
			nx += cols.size() * 7.0 + 8.0
		var n := UI.label(it["note"], UI.Face.ITALIC, 24, Config.SAND)
		n.position = Vector2(nx, 46)
		n.size = Vector2(i * w + w - 24.0 - nx, 48)
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		strip.add_child(n)


# ── Shared panel chrome ──────────────────────────────────────────────

## A panel with an eyebrow, a title and a row of column headers.
## cols: [{text, x, w, align}] in panel pixels. Returns the panel.
func _panel(rect: Rect2, eyebrow: String, title: String, cols: Array) -> Panel:
	var p := UI.panel(rect, UI.panel_style(Config.GOLD, 0.22, 0.8))
	add(p)
	var e := UI.eyebrow(eyebrow, 13, Config.SAND_DIM)
	e.position = Vector2(PAD, 22)
	e.size = Vector2(rect.size.x - PAD * 2, 20)
	p.add_child(e)
	var t := UI.label(title.to_upper(), UI.Face.DISPLAY, 22, Config.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 3)
	t.position = Vector2(PAD - 2, 44)
	t.size = Vector2(rect.size.x - PAD * 2, 36)
	p.add_child(t)
	for c in cols:
		var l := UI.eyebrow(c["text"], 11, Config.SAND_DIM, c.get("align", HORIZONTAL_ALIGNMENT_LEFT))
		l.position = Vector2(c["x"], COLS_Y)
		l.size = Vector2(c["w"], 28)
		p.add_child(l)
	var rule := ColorRect.new()
	rule.color = Color(Config.GOLD, 0.3)
	rule.position = Vector2(PAD, COLS_Y + 30)
	rule.size = Vector2(rect.size.x - PAD * 2, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(rule)
	return p


## A scrolling list under a panel's column headers. The headers stay put;
## only the rows scroll. Rows go in the returned VBoxContainer and should
## be `content_w` wide; the scroll bar sits in the panel's right padding.
func _scroll_list(p: Panel, content_w: float) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.position = Vector2(PAD, BODY_Y)
	sc.size = Vector2(p.size.x - PAD - 10.0, p.size.y - BODY_Y - 14.0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_child(sc)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(content_w, 0)
	list.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc.add_child(list)
	return list


# ── Wins leaderboard ─────────────────────────────────────────────────

func _build_wins(rect: Rect2) -> void:
	var name_x := PAD + 60.0
	var p := _panel(rect, "Wins leaderboard", "Most wins", [
		{"text": "Player", "x": name_x, "w": 200},
		{"text": "Wins", "x": rect.size.x - PAD - 100, "w": 100, "align": HORIZONTAL_ALIGNMENT_RIGHT},
	])
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	chips.position = Vector2(PAD, 88)
	p.add_child(chips)
	var group := ButtonGroup.new()
	var codes := [""]
	for s in data.expansion_spans():
		if s["code"] not in codes:
			codes.append(s["code"])
	if wins_filter not in codes:
		wins_filter = ""
	for code in codes:
		var b := UI.chip("Overall" if code == "" else short_expansion(code), group)
		b.button_pressed = code == wins_filter
		b.pressed.connect(_set_wins_filter.bind(code))
		chips.add_child(b)
	_wins_body = Control.new()
	_wins_body.position = Vector2(0, BODY_Y)
	_wins_body.size = Vector2(rect.size.x, rect.size.y - BODY_Y - 10.0)
	_wins_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(_wins_body)
	_fill_wins()


func _set_wins_filter(code: String) -> void:
	if code == wins_filter:
		return
	wins_filter = code
	_fill_wins()
	_wins_body.modulate.a = 0.0
	tween().tween_property(_wins_body, "modulate:a", 1.0, 0.35)


func _fill_wins() -> void:
	for c in _wins_body.get_children():
		c.queue_free()
	var w := _wins_body.size.x
	var played := data.games_in(wins_filter).size()
	var ranking := data.rank(data.wins(wins_filter), data.total_vp(wins_filter))
	var row_h := minf(92.0, _wins_body.size.y / maxf(1, ranking.size()))
	for i in ranking.size():
		var r: Dictionary = ranking[i]
		var y := i * row_h
		var first: bool = r["rank"] == 1 and r["value"] > 0
		if first:
			var glow := Panel.new()
			var gs := UI.panel_style(Config.GOLD, 0.6, 0.0)
			gs.bg_color = Color(Config.GOLD, 0.08)
			gs.shadow_size = 0
			glow.add_theme_stylebox_override("panel", gs)
			glow.position = Vector2(PAD - 12, y + 6)
			glow.size = Vector2(w - (PAD - 12) * 2, row_h - 12)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_wins_body.add_child(glow)
		var rk := UI.label(UI.roman(r["rank"]), UI.Face.NUMBER, 22,
			Config.GOLD if first else Config.SAND_FAINT)
		rk.position = Vector2(PAD, y)
		rk.size = Vector2(40, row_h)
		_wins_body.add_child(rk)
		var bar := ColorRect.new()
		bar.color = data.colour_of(r["player"])
		bar.position = Vector2(PAD + 44, y + row_h * 0.5 - 20)
		bar.size = Vector2(4, 40)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_wins_body.add_child(bar)
		var nh := UI.font(UI.Face.SERIF_BOLD).get_height(30)
		var ch := UI.font(UI.Face.ITALIC).get_height(20)
		var ny := y + (row_h - (nh + ch - 6.0)) * 0.5
		var nm := UI.label(data.name_of(r["player"]), UI.Face.SERIF_BOLD, 30, Config.SAND)
		nm.position = Vector2(PAD + 60, ny)
		nm.size = Vector2(w - PAD * 2 - 60 - 100, nh)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_wins_body.add_child(nm)
		var rate := roundi(100.0 * r["value"] / maxf(1, played))
		var cap := UI.label("%d%% of %s" % [rate, UI.plural(played, "game")], UI.Face.ITALIC, 20, Config.SAND_DIM)
		cap.position = Vector2(PAD + 61, ny + nh - 6)
		cap.size = nm.size
		cap.size.y = ch
		_wins_body.add_child(cap)
		var v := UI.label(str(r["value"]), UI.Face.NUMBER, 40 if first else 34,
			Config.GOLD_BRIGHT if first else Config.SAND, HORIZONTAL_ALIGNMENT_RIGHT)
		v.position = Vector2(w - PAD - 100, y)
		v.size = Vector2(100, row_h)
		_wins_body.add_child(v)


# ── Wins by leader ───────────────────────────────────────────────────

func _build_leaders(rect: Rect2) -> void:
	var cw := rect.size.x - PAD * 2
	var p := _panel(rect, "Character wins", "By leader", [
		{"text": "Leader", "x": PAD + 36, "w": 160},
		{"text": "Wins", "x": PAD + cw - 100, "w": 100, "align": HORIZONTAL_ALIGNMENT_RIGHT},
	])
	var note := UI.label("Each dot is a win, in the winner's colour", UI.Face.ITALIC, 20, Config.SAND_DIM)
	note.position = Vector2(PAD, 88)
	note.size = Vector2(cw, 34)
	note.clip_text = true
	p.add_child(note)
	var list := _scroll_list(p, cw)
	list.add_theme_constant_override("separation", 0)
	var table := data.leader_table()
	var rank := 0
	for i in table.size():
		var r: Dictionary = table[i]
		if i == 0 or r["wins"] != table[i - 1]["wins"]:
			rank = i + 1
		list.add_child(_leader_row(r, rank, cw))


func _leader_row(r: Dictionary, rank: int, cw: float) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(cw, 42)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if r["wins"] == 0:
		row.modulate.a = 0.45
	var rk := UI.label(str(rank), UI.Face.NUMBER, 17, Config.SAND_FAINT)
	rk.position = Vector2(0, 0)
	rk.size = Vector2(30, 42)
	row.add_child(rk)
	var nm := UI.label(r["leader"], UI.Face.SERIF_BOLD, 24, Config.SAND)
	nm.position = Vector2(36, 0)
	nm.size = Vector2(124, 42)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(nm)
	var pips := Pips.new()
	pips.colours = r["winners"].map(func(p): return data.colour_of(p))
	pips.position = Vector2(166, 0)
	pips.size = Vector2(cw - 166 - 44, 42)
	row.add_child(pips)
	var v := UI.label(str(r["wins"]), UI.Face.NUMBER, 24, Config.SAND, HORIZONTAL_ALIGNMENT_RIGHT)
	v.position = Vector2(cw - 44, 0)
	v.size = Vector2(44, 42)
	row.add_child(v)
	var line := ColorRect.new()
	line.color = Color(Config.GOLD, 0.08)
	line.position = Vector2(0, 41)
	line.size = Vector2(cw, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	return row


# ── Game record ──────────────────────────────────────────────────────

func _build_record(rect: Rect2) -> void:
	var cw := rect.size.x - PAD * 2
	var cols := [{"text": "Game", "x": PAD + 14, "w": 80}]
	var seg := _segments(cw)
	for i in 4:
		cols.append({"text": UI.ordinal(i + 1), "x": PAD + seg["x"] + i * seg["w"] + 18, "w": 80})
	var p := _panel(rect, "Game record", "Every game", cols)
	var legend := FlashLegend.new([
		{"colour": Config.METHOD_COLOURS["Spice"], "text": "Spice"},
		{"colour": Config.METHOD_COLOURS["Solari"], "text": "Solari"},
		{"colour": Config.METHOD_COLOURS["Water"], "text": "Water"},
		{"colour": Config.METHOD_COLOURS["Chaumurky"], "text": "Chaumurky"},
	])
	legend.position = Vector2(PAD, 92)
	legend.size = Vector2(cw, 26)
	p.add_child(legend)
	var list := _scroll_list(p, cw)
	list.add_theme_constant_override("separation", 8)
	var name_px := _name_size(seg["w"] - 12 - 50)
	for i in range(data.games.size() - 1, -1, -1):
		list.add_child(_game_row(data.games[i], cw, seg, name_px))


## Where the four player segments sit in a game row.
func _segments(cw: float) -> Dictionary:
	var x := 100.0
	return {"x": x, "w": (cw - x - 6.0) / 4.0}


## The largest name size (≤ 23px) at which every player's name fits.
func _name_size(width: float) -> int:
	var f := UI.font(UI.Face.SERIF_BOLD)
	var px := 23
	for p in data.players:
		while px > 17 and f.get_string_size(data.name_of(p), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > width:
			px -= 1
	return px


func _game_row(g: Dictionary, cw: float, seg: Dictionary, name_px: int) -> Control:
	var st := UI.panel_style(Config.GOLD, 0.14, 0.55)
	st.shadow_size = 0
	var row := Panel.new()
	row.custom_minimum_size = Vector2(cw, RECORD_ROW_H)
	row.add_theme_stylebox_override("panel", st)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var num := UI.label(str(g["number"]), UI.Face.NUMBER, 24, Config.SAND)
	num.position = Vector2(14, 7)
	num.size = Vector2(seg["x"] - 18, 30)
	row.add_child(num)
	var ex := UI.label(short_expansion(g["expansion"]), UI.Face.ITALIC, 17, Config.SAND_DIM)
	ex.position = Vector2(14, 35)
	ex.size = Vector2(seg["x"] - 18, 22)
	ex.clip_text = true
	ex.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(ex)

	var places := data.placements(g)
	var results: Array = g["results"].duplicate()
	results.sort_custom(func(a, b):
		if places[a["player"]] != places[b["player"]]:
			return places[a["player"]] < places[b["player"]]
		return data.players.find(a["player"]) < data.players.find(b["player"]))
	for i in mini(4, results.size()):
		var r: Dictionary = results[i]
		var x: float = seg["x"] + i * seg["w"]
		var sw: float = seg["w"]
		if r["winner"]:
			var hi := Panel.new()
			var hs := StyleBoxFlat.new()
			var mc: Color = Config.METHOD_COLOURS.get(r["win_method"], Config.GOLD)
			hs.bg_color = Color(mc, 0.08)
			hs.border_color = Color(mc, 0.55)
			hs.set_border_width_all(1)
			hs.set_corner_radius_all(2)
			hi.add_theme_stylebox_override("panel", hs)
			hi.position = Vector2(x + 2, 5)
			hi.size = Vector2(sw - 6, RECORD_ROW_H - 10)
			hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(hi)
		var bar := ColorRect.new()
		bar.color = data.colour_of(r["player"])
		bar.position = Vector2(x + 8, 14)
		bar.size = Vector2(3, RECORD_ROW_H - 28)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
		var nm := UI.label(data.name_of(r["player"]), UI.Face.SERIF_BOLD, name_px, Config.SAND)
		nm.position = Vector2(x + 18, 6)
		nm.size = Vector2(sw - 18 - 52, 30)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(nm)
		var vp := UI.label(str(r["vp"]), UI.Face.NUMBER, 24,
			Config.GOLD_BRIGHT if r["winner"] else Config.SAND, HORIZONTAL_ALIGNMENT_RIGHT)
		vp.position = Vector2(x + sw - 52, 6)
		vp.size = Vector2(40, 30)
		row.add_child(vp)
		var chips := Tiebreaks.new()
		chips.items = _tiebreak_items(r)
		var chips_w: float = chips.measure()
		chips.position = Vector2(x + sw - 12 - chips_w, 36)
		chips.size = Vector2(chips_w, 22)
		row.add_child(chips)
		var ld := UI.label(r["leader"], UI.Face.ITALIC, 18, Config.SAND_DIM)
		ld.position = Vector2(x + 18, 35)
		ld.size = Vector2(sw - 18 - 16 - chips_w - (6.0 if chips_w > 0 else 0.0), 22)
		ld.clip_text = true
		ld.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(ld)

	if g["number"] == added_game:
		st.border_color = Config.GOLD_BRIGHT
		st.bg_color = Color(Config.GOLD, 0.2)
		var tw := tween().set_parallel()
		tw.tween_property(st, "border_color", Color(Config.GOLD, 0.14), 2.6).set_delay(0.8)
		tw.tween_property(st, "bg_color", Color(Config.INK, 0.55), 2.6).set_delay(0.8)
	return row


## Spice, solari, water (when written down) and Chaumurky, as coloured
## dots with their numbers.
func _tiebreak_items(r: Dictionary) -> Array:
	var out := []
	for key in Config.TIEBREAK_ORDER:
		if r[key] >= 0:
			out.append({"colour": Config.METHOD_COLOURS[key.capitalize()], "text": str(r[key])})
	if r["chaumurky"]:
		out.append({"colour": Config.METHOD_COLOURS["Chaumurky"], "text": ""})
	return out


# ── Add a game ───────────────────────────────────────────────────────

func _build_button() -> void:
	var b := Button.new()
	b.text = "Add new game"
	b.add_theme_font_size_override("font_size", 22)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.focus_mode = Control.FOCUS_NONE
	var bw := 220.0
	b.position = Vector2(W - MARGIN - bw, BUTTON_Y)
	b.size = Vector2(bw, BUTTON_H)
	b.pressed.connect(_open_dialog)
	add(b)
	_toast = UI.label(added_message, UI.Face.ITALIC, 24, Config.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	_toast.position = Vector2(MARGIN, BUTTON_Y)
	_toast.size = Vector2(W - MARGIN * 2 - bw - 24, BUTTON_H)
	add(_toast)
	if added_message != "":
		tween().tween_property(_toast, "modulate:a", 0.0, 1.2).set_delay(6.0)


func _open_dialog() -> void:
	if is_instance_valid(_dialog):
		return
	_dialog = AddGameDialog.new(data)
	_dialog.saved.connect(_on_saved)
	add(_dialog)


func _on_saved(game: int, message: String) -> void:
	added_game = game
	added_message = message
	data_changed.emit()


## Short expansion names for filters and the record: Base, Ix, ...
static func short_expansion(code: String) -> String:
	return {"IX": "Ix"}.get(code, code)


# ── Small drawn pieces ───────────────────────────────────────────────

## A row of coloured dots, one per win.
class Pips extends Control:
	var colours: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var step := minf(11.0, size.x / maxf(1, colours.size()))
		for i in colours.size():
			draw_circle(Vector2(5 + i * step, size.y * 0.5), 4.0, colours[i], true, -1.0, true)


## Tie-break numbers as dot + number pairs, drawn left to right.
class Tiebreaks extends Control:
	var items: Array = []
	const PX := 16

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _font() -> Font:
		return UI.font(UI.Face.NUMBER)

	func measure() -> float:
		var w := 0.0
		for it in items:
			w += 10.0 + (_font().get_string_size(it["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, PX).x + 3.0 if it["text"] != "" else 0.0)
		return w + maxf(0, items.size() - 1) * 8.0

	func _draw() -> void:
		var x := 0.0
		var y := size.y * 0.5
		var f := _font()
		for it in items:
			draw_circle(Vector2(x + 4, y), 4.0, it["colour"], true, -1.0, true)
			x += 10.0
			if it["text"] != "":
				draw_string(f, Vector2(x + 1, y + f.get_ascent(PX) * 0.5 - 1), it["text"],
					HORIZONTAL_ALIGNMENT_LEFT, -1, PX, Config.SAND)
				x += f.get_string_size(it["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, PX).x + 3.0
			x += 8.0
