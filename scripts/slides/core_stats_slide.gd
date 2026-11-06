class_name CoreStatsSlide
extends Slide
## MUAD'DIB: a point for every core stat. Each click reveals the next
## stat from data/core_stats.csv: its tile names the leader, the panel on
## the right shows all four values, and the leader scores a point. Ties
## score a point each. After the last stat, the award card.
##
## Options:
##   labels:      {stat name in the CSV -> name shown on screen}
##   lower_wins:  [stat names where the lowest value wins]
##   skip:        [stat names to leave out]

const COLS := 5
const RIGHT_W := 680.0

var opts: Dictionary
var _stats := []        # [{group, stat, label, values: player -> float, winners}]
var _points := {}
var _tiles := []
var _detail: Control
var table: StandingsTable


func _init(options := {}) -> void:
	opts = options


func _numeric_stats() -> Array:
	var out := []
	for s in data.core_stats:
		if s["stat"] in opts.get("skip", []):
			continue
		var values := {}
		var ok := true
		for p in data.players:
			var raw: String = s["values"].get(p, "")
			if not raw.is_valid_float():
				ok = false
				break
			values[p] = float(raw)
		if not ok:
			continue  # text stats such as Fave Alliance
		var lower: bool = s["stat"] in opts.get("lower_wins", [])
		var best: float = values.values().min() if lower else values.values().max()
		var winners := data.players.filter(func(p): return values[p] == best)
		out.append({"group": s["group"], "stat": s["stat"],
			"label": opts.get("labels", {}).get(s["stat"], s["stat"].trim_prefix("Avg. ")),
			"values": values, "winners": winners, "lower": lower})
	return out


func _final_points() -> Dictionary:
	var pts := {}
	for p in data.players:
		pts[p] = 0
	for s in _numeric_stats():
		for p in s["winners"]:
			pts[p] += 1
	return pts


func get_awards() -> Array:
	var r := data.rank(_final_points())
	var winners: Array = r.filter(func(x): return x["rank"] == 1).map(func(x): return x["player"])
	var n := _numeric_stats().size()
	return [{"title": "Muad'Dib", "winners": winners,
		"stat": "%d of %d core stats" % [int(r[0]["value"]), n],
		"note": "A point for leading each of the app's stats"}]


func build() -> void:
	_stats = _numeric_stats()
	var top := add_header("The mind of the Kwisatz Haderach", "Muad'Dib",
		"A point for leading each of the app's %d core stats. Most points wins." % _stats.size()) + 30.0
	var bottom := H - 94.0
	for p in data.players:
		_points[p] = 0

	# Left: one tile per stat.
	var left_w := W - MARGIN * 2 - RIGHT_W - 40.0
	var rows := ceili(_stats.size() / float(COLS))
	var gap := 14.0
	var tw := (left_w - gap * (COLS - 1)) / COLS
	var th := (bottom - top - gap * (rows - 1)) / rows
	for i in _stats.size():
		var rect := Rect2(MARGIN + (i % COLS) * (tw + gap), top + (i / COLS) * (th + gap), tw, th)
		_tiles.append(_make_tile(_stats[i], rect))

	# Right: the current stat in full, then the points table.
	var x := W - MARGIN - RIGHT_W
	var detail_h := 330.0
	add(UI.panel(Rect2(x, top, RIGHT_W, detail_h)))
	_detail = Control.new()
	_detail.position = Vector2(x, top)
	_detail.size = Vector2(RIGHT_W, detail_h)
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add(_detail)
	_show_intro()
	table = StandingsTable.new()
	table.position = Vector2(x, top + detail_h + 20.0)
	table.size = Vector2(RIGHT_W, bottom - table.position.y)
	add(table)
	table.setup(data, [{"key": "points", "header": "Points", "width": 130}])
	for p in data.players:
		table.set_cell(p, "points", "0")

	for i in _stats.size():
		add_step(_reveal.bind(i))
	add_award_card_steps(get_awards())


func _make_tile(s: Dictionary, r: Rect2) -> Dictionary:
	var st := UI.panel_style(Config.GOLD, 0.2, 0.8)
	st.shadow_size = 8
	var panel := UI.panel(r, st)
	add(panel)
	var pad := 16.0
	var g := UI.eyebrow(s["group"], 10, Config.SAND_FAINT)
	g.position = Vector2(pad, 12)
	g.size = Vector2(r.size.x - pad * 2, 18)
	panel.add_child(g)
	var label := UI.label(s["label"], UI.Face.SERIF_BOLD, 24, Config.SAND)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.position = Vector2(pad, 32)
	label.size = Vector2(r.size.x - pad * 2, 60)
	panel.add_child(label)
	var placeholder := UI.label("·  ·  ·", UI.Face.DISPLAY, 18, Config.SAND_FAINT)
	placeholder.position = Vector2(pad, r.size.y - 70)
	placeholder.size = Vector2(120, 50)
	panel.add_child(placeholder)

	var result := Control.new()
	result.size = r.size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.modulate.a = 0.0
	panel.add_child(result)
	var winners: Array = s["winners"]
	var who := data.name_of(winners[0]) if winners.size() == 1 else "Shared ×%d" % winners.size()
	# Shrink long names until they fit the tile.
	var name_px := 26
	var fit_w := r.size.x - pad * 2
	while name_px > 16 and UI.font(UI.Face.SERIF_BOLD).get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, name_px).x > fit_w:
		name_px -= 1
	var nm := UI.label(who, UI.Face.SERIF_BOLD, name_px, data.colour_of(winners[0]) if winners.size() == 1 else Config.SAND)
	nm.position = Vector2(pad, r.size.y - 82)
	nm.size = Vector2(r.size.x - pad * 2, 34)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_child(nm)
	var v := UI.label(_fmt(s, s["values"][winners[0]]), UI.Face.NUMBER, 28, Config.GOLD_BRIGHT)
	v.position = Vector2(pad, r.size.y - 50)
	v.size = Vector2(r.size.x - pad * 2, 36)
	result.add_child(v)
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 4)
	bars.position = Vector2(0, r.size.y - 4)
	bars.size = Vector2(r.size.x, 3)
	for p in winners:
		var b := ColorRect.new()
		b.color = data.colour_of(p)
		b.custom_minimum_size = Vector2(0, 3)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bars.add_child(b)
	result.add_child(bars)
	return {"panel": panel, "style": st, "result": result, "placeholder": placeholder}


func _fmt(s: Dictionary, v: float) -> String:
	var text := ("%d" % v) if is_equal_approx(v, round(v)) else ("%.2f" % v).rstrip("0")
	return text + "%" if s["stat"].begins_with("%") else text


func _clear_detail() -> void:
	for c in _detail.get_children():
		c.queue_free()


func _show_intro() -> void:
	_clear_detail()
	var e := UI.eyebrow("%d trials of the mind" % _stats.size(), 14, Config.GOLD)
	e.position = Vector2(30, 28)
	e.size = Vector2(RIGHT_W - 60, 22)
	_detail.add_child(e)
	var t := UI.label("Who leads each stat?", UI.Face.SERIF_BOLD, 44, Config.SAND)
	t.position = Vector2(30, 60)
	t.size = Vector2(RIGHT_W - 60, 60)
	_detail.add_child(t)
	var s := UI.label("Click to reveal the first", UI.Face.ITALIC, 28, Config.SAND_DIM)
	s.position = Vector2(30, 124)
	s.size = Vector2(RIGHT_W - 60, 40)
	_detail.add_child(s)


func _show_detail(s: Dictionary) -> void:
	_clear_detail()
	var e := UI.eyebrow("%s  ·  %s" % [s["group"], "lowest wins" if s["lower"] else "highest wins"], 13, Config.GOLD)
	e.position = Vector2(30, 24)
	e.size = Vector2(RIGHT_W - 60, 22)
	_detail.add_child(e)
	var t := UI.label(s["label"], UI.Face.SERIF_BOLD, 40, Config.SAND)
	t.position = Vector2(30, 50)
	t.size = Vector2(RIGHT_W - 60, 52)
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail.add_child(t)
	var values: Dictionary = s["values"]
	var order: Array = data.players.duplicate()
	order.sort_custom(func(a, b): return values[a] < values[b] if s["lower"] else values[a] > values[b])
	var top_v: float = 0.0
	for p in order:
		top_v = maxf(top_v, values[p])
	var y := 118.0
	var row_h := 50.0
	var name_w := 230.0
	var bar_x := 30.0 + name_w
	var bar_max := RIGHT_W - bar_x - 30.0 - 100.0
	for p in order:
		var lead: bool = p in s["winners"]
		var nm := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, 28, data.colour_of(p) if lead else Config.SAND_DIM)
		nm.position = Vector2(30, y)
		nm.size = Vector2(name_w - 10, row_h)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_detail.add_child(nm)
		var bar := ColorRect.new()
		bar.color = Color(data.colour_of(p), 0.95 if lead else 0.45)
		bar.position = Vector2(bar_x, y + row_h * 0.5 - 5)
		bar.size = Vector2(0, 10)
		_detail.add_child(bar)
		var w: float = bar_max * (values[p] / top_v if top_v > 0 else 0.0)
		_detail.create_tween().tween_property(bar, "size:x", w, 0.7) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var v := UI.label(_fmt(s, values[p]), UI.Face.NUMBER, 28, Config.GOLD_BRIGHT if lead else Config.SAND,
			HORIZONTAL_ALIGNMENT_RIGHT)
		v.position = Vector2(RIGHT_W - 30 - 100, y)
		v.size = Vector2(100, row_h)
		_detail.add_child(v)
		y += row_h


func _reveal(i: int) -> void:
	var s: Dictionary = _stats[i]
	var tile: Dictionary = _tiles[i]
	for t in _tiles:
		t["style"].border_color = Color(Config.GOLD, 0.2)
	var st: StyleBoxFlat = tile["style"]
	st.border_color = Color(Config.GOLD_BRIGHT, 0.9)
	_show_detail(s)
	for p in s["winners"]:
		_points[p] += 1
		table.set_cell(p, "points", str(_points[p]))
		table.flash_cell(p, "points", Config.GOLD_BRIGHT)
	table.sort_by(_points)
	var tw := tween().set_parallel()
	tw.tween_property(tile["placeholder"], "modulate:a", 0.0, 0.25)
	tw.tween_property(tile["result"], "modulate:a", 1.0, 0.6)
