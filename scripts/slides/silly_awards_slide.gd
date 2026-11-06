class_name SillyAwardsSlide
extends Slide
## Three side-by-side "honours" nobody wants. Each click reveals one:
## the panel fills with everyone's tally and the "winner" is lit up.
##
## Each entry in `awards`:
##   {eyebrow, title, values: player -> number, unit,
##    lowest_wins (optional, default false),
##    detail (optional): func(player) -> String shown under the number}

var awards: Array = []
var _panels := []


func _init(list: Array) -> void:
	awards = list


func get_awards() -> Array:
	var out := []
	for a in awards:
		var r := _rank(a)
		var winners: Array = r.filter(func(x): return x["rank"] == 1).map(func(x): return x["player"])
		out.append({"title": a["title"], "winners": winners,
			"stat": _value_text(a, r[0]["player"], r[0]["value"], true)})
	return out


func _rank(a: Dictionary) -> Array:
	if not a.get("lowest_wins", false):
		return data.rank(a["values"])
	var flipped := {}
	for p in a["values"]:
		flipped[p] = -a["values"][p]
	var r := data.rank(flipped)
	for x in r:
		x["value"] = -x["value"]
	return r


func _value_text(a: Dictionary, _p: String, v: float, long := false) -> String:
	if long:
		return UI.plural(int(v), a.get("unit", "point"))
	return str(int(v))


func build() -> void:
	var top := add_header("Honours no one wants", "The sandworm's dinner",
		"Three awards for the ones who fed the worm") + 34.0
	var n := awards.size()
	var gap := 28.0
	var w := (W - MARGIN * 2 - gap * (n - 1)) / n
	var h := H - 94.0 - top
	for i in n:
		_panels.append(_make_panel(awards[i], Rect2(MARGIN + i * (w + gap), top, w, h)))
		add_step(_reveal.bind(i))


func _make_panel(a: Dictionary, rect: Rect2) -> Dictionary:
	var st := UI.panel_style(Config.GOLD, 0.22, 0.8)
	var panel := UI.panel(rect, st)
	add(panel)
	var pad := 32.0
	var e := UI.eyebrow(a.get("eyebrow", ""), 13, Config.SAND_DIM)
	e.position = Vector2(pad, 30)
	e.size = Vector2(rect.size.x - pad * 2, 22)
	panel.add_child(e)
	var t := UI.label(a["title"].to_upper(), UI.Face.DISPLAY, 26, Config.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 3)
	t.position = Vector2(pad - 2, 58)
	t.size = Vector2(rect.size.x - pad * 2, 44)
	panel.add_child(t)
	var o := Ornament.new(rect.size.x * 0.5)
	o.position = Vector2(pad, 110)
	panel.add_child(o)

	var placeholder := UI.label("·  ·  ·", UI.Face.DISPLAY, 26, Config.SAND_FAINT)
	placeholder.position = Vector2(pad, 150)
	placeholder.size = Vector2(200, 60)
	panel.add_child(placeholder)

	# Everyone's tally, the "winner" first.
	var body := Control.new()
	body.position = Vector2(0, 146)
	body.size = Vector2(rect.size.x, rect.size.y - 146)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.modulate.a = 0.0
	panel.add_child(body)
	var ranking := _rank(a)
	var row_h := minf(118.0, (body.size.y - 20.0) / maxf(1, ranking.size()))
	var gauges := []
	var best := 0.0
	for r in ranking:
		best = maxf(best, absf(r["value"]))
	for j in ranking.size():
		var r: Dictionary = ranking[j]
		var p: String = r["player"]
		var y := j * row_h
		var first: bool = r["rank"] == 1
		if first:
			var glow := Panel.new()
			var gs := UI.panel_style(Config.GOLD, 0.7, 0.0)
			gs.bg_color = Color(Config.GOLD, 0.08)
			gs.shadow_size = 0
			glow.add_theme_stylebox_override("panel", gs)
			glow.position = Vector2(14, y + 4)
			glow.size = Vector2(rect.size.x - 28, row_h - 8)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(glow)
		var bar := ColorRect.new()
		bar.color = data.colour_of(p)
		bar.position = Vector2(pad, y + row_h * 0.5 - 18)
		bar.size = Vector2(4, 36)
		body.add_child(bar)
		var detail: String = a["detail"].call(p) if a.has("detail") else ""
		var name_size := 40 if first else 32
		var nh := UI.font(UI.Face.SERIF_BOLD).get_height(name_size)
		var dh := UI.font(UI.Face.ITALIC).get_height(22) if detail != "" else 0.0
		var ny := y + (row_h - (nh + dh - (6.0 if detail != "" else 0.0))) * 0.5
		var nm := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, name_size, Config.SAND)
		nm.position = Vector2(pad + 18, ny)
		nm.size = Vector2(rect.size.x - pad * 2 - 110, nh)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		body.add_child(nm)
		if detail != "":
			var d := UI.label(detail, UI.Face.ITALIC, 22, Config.SAND_DIM)
			d.position = Vector2(pad + 19, ny + nh - 6)
			d.size = Vector2(rect.size.x - pad * 2 - 110, dh)
			d.clip_text = true
			d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			body.add_child(d)
		var v := UI.label(_value_text(a, p, r["value"]), UI.Face.NUMBER, 44 if first else 36,
			Config.GOLD_BRIGHT if first else Config.SAND, HORIZONTAL_ALIGNMENT_RIGHT)
		v.position = Vector2(rect.size.x - pad - 120, y)
		v.size = Vector2(120, row_h)
		body.add_child(v)
	return {"panel": panel, "style": st, "body": body, "placeholder": placeholder}


func _reveal(i: int) -> void:
	var c: Dictionary = _panels[i]
	var body: Control = c["body"]
	var st: StyleBoxFlat = c["style"]
	body.position.y += 16
	var tw := tween().set_parallel()
	tw.tween_property(c["placeholder"], "modulate:a", 0.0, 0.3)
	tw.tween_property(st, "border_color", Color(Config.GOLD, 0.75), 0.6)
	tw.tween_property(body, "modulate:a", 1.0, 0.8).set_delay(0.2)
	tw.tween_property(body, "position:y", 146.0, 0.9).set_delay(0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	play(tw, func():
		c["placeholder"].modulate.a = 0.0
		st.border_color = Color(Config.GOLD, 0.75)
		body.modulate.a = 1.0
		body.position.y = 146.0)
