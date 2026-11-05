class_name RankingRevealSlide
extends Slide
## A slow top-N reveal: 4th place first, 1st place last, one per click.
## Used for the four game-mode awards, and the quickest way to add a
## new award: give it a title and a Dictionary of player -> score.
##
##   RankingRevealSlide.new({
##       "eyebrow":  "Rise of Ix",
##       "title":    "Leader of IX",
##       "subtitle": "Most wins in the Rise of Ix expansion",
##       "values":   data.wins("IX"),          # player -> number
##       "unit":     "win",                    # shown as "5 WINS"
##       # optional:
##       "tiebreak": data.total_vp("IX"),      # separates equal scores
##       "tiebreak_name": "total VP",
##       "detail":   func(p): return "...",    # small line under a name
##       "show_top": 4,
##   })

var opts: Dictionary

var _rows := []
var _ranking := []


func _init(options: Dictionary) -> void:
	opts = options


func get_awards() -> Array:
	var r := _rank()
	var winners: Array = r.filter(func(x): return x["rank"] == 1).map(func(x): return x["player"])
	return [{"title": opts["title"], "winners": winners,
		"stat": UI.plural(int(r[0]["value"]), opts.get("unit", "point"))}]


func _rank() -> Array:
	return data.rank(opts["values"], opts.get("tiebreak", {}))


func build() -> void:
	var top := add_header(opts.get("eyebrow", ""), opts["title"], opts.get("subtitle", "")) + 40.0
	_ranking = _rank()
	var n: int = mini(opts.get("show_top", 4), _ranking.size())
	var max_value := 0.0
	for r in _ranking:
		max_value = maxf(max_value, r["value"])

	# 1st place is the tallest row; the rest share the remaining height.
	var avail := H - 100.0 - top
	var gap := 18.0
	var first_h := minf(170.0, avail * 0.3)
	var other_h := minf(130.0, (avail - first_h - gap * (n - 1)) / maxf(1.0, n - 1))
	var y := top
	for i in n:
		var h := first_h if i == 0 else other_h
		_rows.append(_make_row(i, _ranking[i], Rect2(MARGIN, y, W - MARGIN * 2, h), max_value))
		y += h + gap

	# Reveal from the bottom of the list up.
	for i in range(n - 1, -1, -1):
		add_step(_reveal.bind(i))


func _make_row(i: int, r: Dictionary, rect: Rect2, max_value: float) -> Dictionary:
	var first := i == 0
	var st := UI.panel_style(Config.GOLD, 0.6 if first else 0.22, 0.8)
	if first:
		st.set_border_width_all(2)
	var panel := UI.panel(rect, st)
	add(panel)
	var h := rect.size.y

	var numeral := UI.label(UI.roman(r["rank"]), UI.Face.NUMBER, 60 if first else 46,
		Config.GOLD if first else Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER, 2)
	numeral.position = Vector2(0, 0)
	numeral.size = Vector2(150, h)
	panel.add_child(numeral)

	var hidden := Control.new()
	hidden.size = rect.size
	hidden.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hidden.modulate.a = 0.0
	panel.add_child(hidden)

	var placeholder := UI.label("·  ·  ·", UI.Face.DISPLAY, 26, Config.SAND_FAINT)
	placeholder.position = Vector2(184, 0)
	placeholder.size = Vector2(400, h)
	panel.add_child(placeholder)

	var p: String = r["player"]
	var bar := ColorRect.new()
	bar.color = data.colour_of(p)
	bar.position = Vector2(150, h * 0.5 - 30)
	bar.size = Vector2(4, 60)
	hidden.add_child(bar)

	var detail_text := ""
	if opts.has("detail"):
		detail_text = opts["detail"].call(p)
	var note := _tie_note(i)
	if note != "":
		detail_text = note if detail_text == "" else detail_text + "  ·  " + note

	# Name with its detail line beneath, centred as one block.
	var name_size := 76 if first else 58
	var name_h := UI.font(UI.Face.SERIF_BOLD).get_height(name_size)
	var detail_h := UI.font(UI.Face.ITALIC).get_height(27) if detail_text != "" else 0.0
	var name_y := (h - (name_h + detail_h - (8.0 if detail_text != "" else 0.0))) * 0.5
	var name_l := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, name_size,
		Color.WHITE if first else Config.SAND)
	if first:
		name_l.material = UI.gold_material()
	name_l.position = Vector2(184, name_y)
	name_l.size = Vector2(rect.size.x - 184 - 300, name_h)
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hidden.add_child(name_l)

	if detail_text != "":
		var d := UI.label(detail_text, UI.Face.ITALIC, 27, Config.SAND_DIM)
		d.position = Vector2(186, name_y + name_h - 8.0)
		d.size = Vector2(rect.size.x - 186 - 300, detail_h)
		d.clip_text = true
		d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hidden.add_child(d)

	# Score with its unit beneath, right-aligned, centred as one block.
	var value_size := 72 if first else 56
	var value_h := UI.font(UI.Face.NUMBER).get_height(value_size)
	var unit_h := 22.0
	var value_y := (h - (value_h + unit_h - 12.0)) * 0.5
	var value_l := UI.label("0", UI.Face.NUMBER, value_size,
		Config.GOLD_BRIGHT if first else Config.SAND, HORIZONTAL_ALIGNMENT_RIGHT)
	value_l.position = Vector2(rect.size.x - 300, value_y)
	value_l.size = Vector2(262, value_h)
	hidden.add_child(value_l)
	var unit := UI.eyebrow(_unit_word(int(r["value"])), 13, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	unit.position = Vector2(rect.size.x - 300, value_y + value_h - 12.0)
	unit.size = Vector2(258, unit_h)
	hidden.add_child(unit)

	# A soft wash in the player's colour, filled to their share of the top score.
	var gauge := ColorRect.new()
	gauge.color = Color(data.colour_of(p), 0.10)
	gauge.position = Vector2(1, 1)
	gauge.size = Vector2(0, h - 2)
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(gauge)
	panel.move_child(gauge, 0)
	var full: float = (rect.size.x - 2) * (r["value"] / max_value if max_value > 0 else 0.0)

	return {"panel": panel, "hidden": hidden, "placeholder": placeholder, "value": value_l,
		"gauge": gauge, "gauge_w": full, "score": r["value"], "first": first, "numeral": numeral,
		"style": st}


## Explains a tie with the row above or below, if there is one.
func _tie_note(i: int) -> String:
	var r: Dictionary = _ranking[i]
	var tied_rows := []
	for j in [i - 1, i + 1]:
		if j >= 0 and j < _ranking.size() and _ranking[j]["value"] == r["value"]:
			tied_rows.append(_ranking[j])
	if tied_rows.is_empty():
		return ""
	var level := UI.plural(int(r["value"]), opts.get("unit", "point"))
	if not opts.has("tiebreak"):
		return "level on %s" % level
	for t in tied_rows:
		if t["rank"] == r["rank"]:
			return "level on %s and %s" % [level, opts.get("tiebreak_name", "the tie-break")]
	return "level on %s, split by %s: %d" % [level, opts.get("tiebreak_name", "tie-break"), int(r["tiebreak"])]


func _unit_word(n: int) -> String:
	var u: String = opts.get("unit", "point")
	return u if n == 1 else u + "s"


func _reveal(i: int) -> void:
	var row: Dictionary = _rows[i]
	var tw := tween()
	if row["first"]:
		# A held breath: the frame pulses before the name appears.
		var st: StyleBoxFlat = row["style"]
		for k in 3:
			tw.tween_property(st, "border_color", Color(Config.GOLD_BRIGHT, 1.0), 0.28)
			tw.tween_property(st, "border_color", Color(Config.GOLD, 0.35), 0.28)
		tw.tween_property(st, "border_color", Color(Config.GOLD_BRIGHT, 0.9), 0.2)
		tw.tween_callback(func():
			var p: Panel = row["panel"]
			add(GoldBurst.new(Rect2(p.position + Vector2(160, 10), p.size - Vector2(200, 20)), 220)))
	tw.tween_property(row["placeholder"], "modulate:a", 0.0, 0.25)
	var hidden: Control = row["hidden"]
	hidden.position.x = -24
	tw.set_parallel()
	tw.tween_property(hidden, "modulate:a", 1.0, 0.7)
	tw.tween_property(hidden, "position:x", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var value_l: Label = row["value"]
	var score: float = row["score"]
	tw.tween_method(func(v): value_l.text = str(int(round(v))), 0.0, score, 1.0)
	var gauge: ColorRect = row["gauge"]
	tw.tween_property(gauge, "size:x", row["gauge_w"], 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if row["first"]:
		tw.tween_property(row["numeral"], "modulate", Color(1.4, 1.3, 1.0), 0.6)
	play(tw, func():
		row["placeholder"].modulate.a = 0.0
		hidden.modulate.a = 1.0
		hidden.position.x = 0.0
		value_l.text = str(int(score))
		gauge.size.x = row["gauge_w"]
		if row["first"]:
			row["numeral"].modulate = Color(1.4, 1.3, 1.0)
			row["style"].border_color = Color(Config.GOLD_BRIGHT, 0.9))
