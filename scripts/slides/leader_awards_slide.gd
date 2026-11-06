class_name LeaderAwardsSlide
extends Slide
## THE DUNE 1 AWARD: one column per leader, showing each player's win
## rate with that leader. Each click reveals the next leader; the best
## win rate is lit gold. Level rates are split by more wins.
##
##   LeaderAwardsSlide.new(["Baron", "Leto", "Paul", "Rabban"])
## Leader names must match the leader column of games.csv.

var leaders: Array = []
var titles := {}   # optional: leader -> award name shown on the finale
var _cols := []


func _init(leader_names: Array, award_titles := {}) -> void:
	leaders = leader_names
	titles = award_titles


func _ranking(leader: String) -> Array:
	var rec := data.leader_record(leader)
	var rate := {}
	var wins := {}
	for p in data.players:
		var r: Dictionary = rec[p]
		# Players who never picked this leader sit below everyone who did.
		rate[p] = float(r["wins"]) / r["plays"] if r["plays"] > 0 else -1.0
		wins[p] = r["wins"]
	var out := data.rank(rate, wins)
	for x in out:
		x["plays"] = rec[x["player"]]["plays"]
		x["wins"] = rec[x["player"]]["wins"]
	return out


func get_awards() -> Array:
	var out := []
	for l in leaders:
		var r := _ranking(l)
		var winners: Array = r.filter(func(x): return x["rank"] == 1).map(func(x): return x["player"])
		out.append({"title": titles.get(l, "Dune 1 · %s" % l), "winners": winners,
			"stat": "%d%% win rate as %s (%d of %d)" % [roundi(r[0]["value"] * 100), l, r[0]["wins"], r[0]["plays"]]})
	return out


func build() -> void:
	var top := add_header("The originals", "The Dune 1 award",
		"Who wins most often with the four leaders of the first film?") + 34.0
	var n := leaders.size()
	var gap := 24.0
	var w := (W - MARGIN * 2 - gap * (n - 1)) / n
	var h := H - 94.0 - top
	for i in n:
		_cols.append(_make_column(leaders[i], Rect2(MARGIN + i * (w + gap), top, w, h)))
		add_step(_reveal.bind(i))


func _make_column(leader: String, rect: Rect2) -> Dictionary:
	var st := UI.panel_style(Config.GOLD, 0.22, 0.8)
	var panel := UI.panel(rect, st)
	add(panel)
	var pad := 28.0
	var e := UI.eyebrow("Played as", 12, Config.SAND_DIM)
	e.position = Vector2(pad, 28)
	e.size = Vector2(rect.size.x - pad * 2, 20)
	panel.add_child(e)
	var t := UI.label(leader.to_upper(), UI.Face.DISPLAY, 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4)
	t.material = UI.gold_material()
	t.position = Vector2(pad - 2, 52)
	t.size = Vector2(rect.size.x - pad * 2, 52)
	panel.add_child(t)
	var o := Ornament.new(rect.size.x * 0.55)
	o.position = Vector2(pad, 112)
	panel.add_child(o)
	var placeholder := UI.label("·  ·  ·", UI.Face.DISPLAY, 26, Config.SAND_FAINT)
	placeholder.position = Vector2(pad, 150)
	placeholder.size = Vector2(200, 60)
	panel.add_child(placeholder)

	var body := Control.new()
	body.position = Vector2(0, 144)
	body.size = Vector2(rect.size.x, rect.size.y - 150)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.modulate.a = 0.0
	panel.add_child(body)
	var ranking := _ranking(leader)
	var row_h := (body.size.y - 10.0) / maxf(1, ranking.size())
	var bars := []
	for j in ranking.size():
		var r: Dictionary = ranking[j]
		var p: String = r["player"]
		var y := j * row_h
		var first: bool = r["rank"] == 1 and r["plays"] > 0
		if first:
			var glow := Panel.new()
			var gs := UI.panel_style(Config.GOLD, 0.7, 0.0)
			gs.bg_color = Color(Config.GOLD, 0.08)
			gs.shadow_size = 0
			glow.add_theme_stylebox_override("panel", gs)
			glow.position = Vector2(12, y + 4)
			glow.size = Vector2(rect.size.x - 24, row_h - 8)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(glow)
		var nm := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, 34, data.colour_of(p) if r["plays"] > 0 else Config.SAND_FAINT)
		nm.position = Vector2(pad, y + 14)
		nm.size = Vector2(rect.size.x - pad * 2 - 100, 44)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		body.add_child(nm)
		var record := "never played" if r["plays"] == 0 else "%d of %d won" % [r["wins"], r["plays"]]
		var d := UI.label(record, UI.Face.ITALIC, 22, Config.SAND_DIM)
		d.position = Vector2(pad + 1, y + 56)
		d.size = Vector2(rect.size.x - pad * 2 - 100, 30)
		body.add_child(d)
		var pct := "–" if r["plays"] == 0 else "%d%%" % roundi(r["value"] * 100)
		var v := UI.label(pct, UI.Face.NUMBER, 40 if first else 32, Config.GOLD_BRIGHT if first else Config.SAND,
			HORIZONTAL_ALIGNMENT_RIGHT)
		v.position = Vector2(rect.size.x - pad - 110, y + 10)
		v.size = Vector2(110, 54)
		body.add_child(v)
		# Win-rate gauge under each row.
		var track := ColorRect.new()
		track.color = Color(Config.SAND, 0.07)
		track.position = Vector2(pad, y + row_h - 22)
		track.size = Vector2(rect.size.x - pad * 2, 4)
		body.add_child(track)
		var bar := ColorRect.new()
		bar.color = data.colour_of(p)
		bar.position = track.position
		bar.size = Vector2(0, 4)
		body.add_child(bar)
		bars.append({"bar": bar, "w": track.size.x * maxf(0.0, r["value"])})
	return {"panel": panel, "style": st, "body": body, "placeholder": placeholder, "bars": bars}


func _reveal(i: int) -> void:
	var c: Dictionary = _cols[i]
	var body: Control = c["body"]
	var st: StyleBoxFlat = c["style"]
	var tw := tween().set_parallel()
	tw.tween_property(c["placeholder"], "modulate:a", 0.0, 0.3)
	tw.tween_property(st, "border_color", Color(Config.GOLD, 0.75), 0.6)
	tw.tween_property(body, "modulate:a", 1.0, 0.7).set_delay(0.15)
	for b in c["bars"]:
		tw.tween_property(b["bar"], "size:x", b["w"], 1.1).set_delay(0.3) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	play(tw, func():
		c["placeholder"].modulate.a = 0.0
		st.border_color = Color(Config.GOLD, 0.75)
		body.modulate.a = 1.0
		for b in c["bars"]:
			b["bar"].size.x = b["w"])
