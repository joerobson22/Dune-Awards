class_name LeaderAwardsSlide
extends Slide
## THE LEADER AWARD: a row per leader, a column per player, each cell a
## win rate. Each click reveals the next leader: the best win rate is lit
## gold and scores a point. Most points takes the Leader Award.
##
##   LeaderAwardsSlide.new(["Baron", "Rabban", "Paul", ...])
## Leader names must match the leader column of games.csv.
##
## Level rates are split by more wins, then shared (a point each). A
## leader nobody has won with scores no points.
##
## A second array after the award name adds a second award: the best
## win rate any player has with a single leader from that list. Its card
## follows the Leader Award card on the next click.
##   LeaderAwardsSlide.new(["Baron", ...], "Leader Award",
##       ["Baron", "Paul", "Tessia", ...], "Master of One")
## Only leaders played at least Config.SINGLE_LEADER_MIN_GAMES times
## count; a fifth argument overrides that for one slide (handy for a box
## with few games). Level rates are split by more wins, then shared. No
## card is shown if nobody qualifies or nobody won with a listed leader.

const NAME_W := 300.0
const HEAD_H := 64.0
const FOOT_H := 92.0

var leaders: Array = []
var title := "Leader Award"
var single_leaders: Array = []
var single_title := "Master of One"
var single_min_games := Config.SINGLE_LEADER_MIN_GAMES
var _rows := []
var _points := {}        # player -> Label in the footer
var _score := {}         # player -> points shown so far
var _col_x := {}         # player -> column x
var _col_w := 0.0
var _foot_y := 0.0


func _init(leader_names: Array, award_title := "Leader Award",
		single_leader_names: Array = [], single_award_title := "Master of One",
		min_games := Config.SINGLE_LEADER_MIN_GAMES) -> void:
	leaders = leader_names
	title = award_title
	single_leaders = single_leader_names
	single_title = single_award_title
	single_min_games = maxi(1, min_games)


## The win-rate ranking for one leader. Never-played rates are -1.
func _ranking(leader: String) -> Array:
	var rec := data.leader_record(leader)
	var rate := {}
	var wins := {}
	for p in data.players:
		var r: Dictionary = rec[p]
		rate[p] = float(r["wins"]) / r["plays"] if r["plays"] > 0 else -1.0
		wins[p] = r["wins"]
	var out := data.rank(rate, wins)
	for x in out:
		x["plays"] = rec[x["player"]]["plays"]
		x["wins"] = rec[x["player"]]["wins"]
	return out


## Who scores the point for a leader: the top rank, if they ever won.
func _leader_winners(ranking: Array) -> Array:
	if ranking.is_empty() or ranking[0]["wins"] == 0:
		return []
	return ranking.filter(func(x): return x["rank"] == 1).map(func(x): return x["player"])


func _final_points() -> Dictionary:
	var pts := {}
	for p in data.players:
		pts[p] = 0
	for l in leaders:
		for p in _leader_winners(_ranking(l)):
			pts[p] += 1
	return pts


func get_awards() -> Array:
	var r := data.rank(_final_points(), data.total_vp())
	var winners: Array = r.filter(func(x): return x["rank"] == 1).map(func(x): return x["player"])
	var awards := [{"title": title, "winners": winners,
		"stat": "best win rate with %d of %d leaders" % [int(r[0]["value"]), leaders.size()]}]
	var single := _single_leader_award()
	if not single.is_empty():
		awards.append(single)
	return awards


## Each player's best record with one leader from single_leaders:
## player -> {rate, wins, plays, leaders}. Players short of the minimum
## games with every listed leader are left out. A player level on rate
## and wins with two leaders keeps both.
func _best_single_records() -> Dictionary:
	var best := {}
	for l in single_leaders:
		var rec := data.leader_record(l)
		for p in data.players:
			var r: Dictionary = rec[p]
			if r["plays"] < single_min_games:
				continue
			var rate: float = float(r["wins"]) / r["plays"]
			var b: Dictionary = best.get(p, {})
			if b.is_empty() or rate > b["rate"] or (rate == b["rate"] and r["wins"] > b["wins"]):
				best[p] = {"rate": rate, "wins": r["wins"], "plays": r["plays"], "leaders": [l]}
			elif rate == b["rate"] and r["wins"] == b["wins"]:
				b["leaders"].append(l)
	return best


## The best win rate with a single leader, as an award card. Empty if
## no listed leader was played enough or nobody won with one.
func _single_leader_award() -> Dictionary:
	if single_leaders.is_empty():
		return {}
	var best := _best_single_records()
	var rate := {}
	var wins := {}
	for p in data.players:
		rate[p] = best[p]["rate"] if best.has(p) else -1.0
		wins[p] = best[p]["wins"] if best.has(p) else -1
	var r := data.rank(rate, wins)
	if r[0]["value"] <= 0.0:
		push_warning("%s: no one has won with a leader they played %d+ times." \
			% [single_title, single_min_games])
		return {}
	var winners: Array = r.filter(func(x): return x["rank"] == 1).map(func(x): return x["player"])
	var top: Dictionary = best[winners[0]]
	var pct := roundi(top["rate"] * 100)
	var min_note := "Best win rate with one leader  ·  at least %s" % UI.plural(single_min_games, "game")
	if winners.size() == 1:
		return {"title": single_title, "winners": winners,
			"stat": "%d%% as %s  ·  %d of %d won" % [pct, _leaders_text(top["leaders"]), top["wins"], top["plays"]],
			"note": min_note}
	# Shared: say who did it with which leader on the card's note line.
	var who := winners.map(func(p): return "%s as %s" % [data.name_of(p), _leaders_text(best[p]["leaders"])])
	return {"title": single_title, "winners": winners,
		"stat": "%d%% with one leader  ·  %d of %d won" % [pct, top["wins"], top["plays"]],
		"note": "  ·  ".join(who)}


func _leaders_text(names: Array) -> String:
	return " & ".join(names)


func build() -> void:
	var top := add_header("The great houses", "The " + title,
		"A point for the best win rate with each leader. Most points wins.") + 30.0
	var bottom := H - 94.0
	var players: Array = data.players
	_col_w = (W - MARGIN * 2 - NAME_W) / players.size()
	var row_h := (bottom - top - HEAD_H - FOOT_H) / leaders.size()
	add(UI.panel(Rect2(MARGIN, top, W - MARGIN * 2, bottom - top)))

	# Column heads: one per player, in their colour.
	for i in players.size():
		var p: String = players[i]
		var x := MARGIN + NAME_W + i * _col_w
		_col_x[p] = x
		var n := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, 30, data.colour_of(p), HORIZONTAL_ALIGNMENT_CENTER)
		n.position = Vector2(x, top + 12)
		n.size = Vector2(_col_w, 40)
		add(n)
	var e := UI.eyebrow("Leader", 12, Config.SAND_DIM)
	e.position = Vector2(MARGIN + 32, top + 26)
	e.size = Vector2(200, 20)
	add(e)
	_rule(top + HEAD_H, 0.35)

	for i in leaders.size():
		var y := top + HEAD_H + i * row_h
		_rows.append(_make_row(leaders[i], y, row_h))
		if i > 0:
			_rule(y, 0.1)
		add_step(_reveal.bind(i))

	# Footer: the running points.
	_foot_y = bottom - FOOT_H
	_rule(_foot_y, 0.35)
	var f := UI.eyebrow("Points", 15, Config.GOLD)
	f.position = Vector2(MARGIN + 32, _foot_y + 36)
	f.size = Vector2(200, 22)
	add(f)
	for p in players:
		_score[p] = 0
		var v := UI.label("0", UI.Face.NUMBER, 46, Config.SAND, HORIZONTAL_ALIGNMENT_CENTER)
		v.position = Vector2(_col_x[p], _foot_y + 12)
		v.size = Vector2(_col_w, 68)
		v.pivot_offset = v.size * 0.5
		add(v)
		_points[p] = v
	add_award_card_steps(get_awards())


func _rule(y: float, alpha: float) -> void:
	var r := ColorRect.new()
	r.color = Color(Config.GOLD, alpha)
	r.position = Vector2(MARGIN + 24, y)
	r.size = Vector2(W - MARGIN * 2 - 48, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add(r)


func _make_row(leader: String, y: float, h: float) -> Dictionary:
	var ranking := _ranking(leader)
	var winners := _leader_winners(ranking)
	# Shrink a long name (e.g. Feyd-Rautha) to fit the name column.
	var name_px := 24
	var nf := UI.font(UI.Face.DISPLAY, 3)
	while name_px > 14 and nf.get_string_size(leader.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, name_px).x > NAME_W - 44:
		name_px -= 1
	var nm := UI.label(leader.to_upper(), UI.Face.DISPLAY, name_px, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 3)
	nm.material = UI.gold_material()
	nm.position = Vector2(MARGIN + 30, y)
	nm.size = Vector2(NAME_W - 40, h)
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add(nm)

	var placeholder := UI.label("·  ·  ·", UI.Face.DISPLAY, 22, Config.SAND_FAINT)
	placeholder.position = Vector2(MARGIN + NAME_W + 28, y)
	placeholder.size = Vector2(200, h)
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add(placeholder)

	var cells := Control.new()
	cells.size = Vector2(W, H)
	cells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cells.modulate.a = 0.0
	add(cells)
	var bars := []
	var glows := []
	for r in ranking:
		var p: String = r["player"]
		var x: float = _col_x[p]
		var won: bool = p in winners
		if won:
			var glow := Panel.new()
			var gs := UI.panel_style(Config.GOLD, 0.7, 0.0)
			gs.bg_color = Color(Config.GOLD, 0.09)
			gs.shadow_size = 0
			glow.add_theme_stylebox_override("panel", gs)
			glow.position = Vector2(x + 14, y + 6)
			glow.size = Vector2(_col_w - 28, h - 12)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cells.add_child(glow)
			glows.append(glow)
		var played: bool = r["plays"] > 0
		var pct := UI.label("%d%%" % roundi(r["value"] * 100) if played else "–", UI.Face.NUMBER,
			32 if won else 28, Config.GOLD_BRIGHT if won else (Config.SAND if played else Config.SAND_FAINT),
			HORIZONTAL_ALIGNMENT_RIGHT)
		pct.position = Vector2(x + 20, y)
		pct.size = Vector2(_col_w * 0.42 - 20, h - 6)
		pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cells.add_child(pct)
		var rec := UI.label("%d of %d" % [r["wins"], r["plays"]] if played else "never played", UI.Face.ITALIC, 22,
			Config.SAND_DIM if played else Config.SAND_FAINT)
		rec.position = Vector2(x + _col_w * 0.42 + 14, y)
		rec.size = Vector2(_col_w * 0.58 - 34, h - 6)
		rec.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cells.add_child(rec)
		# A thin win-rate gauge along the foot of the cell.
		var track := ColorRect.new()
		track.color = Color(Config.SAND, 0.06)
		track.position = Vector2(x + 28, y + h - 16)
		track.size = Vector2(_col_w - 56, 3)
		cells.add_child(track)
		var bar := ColorRect.new()
		bar.color = data.colour_of(p)
		bar.position = track.position
		bar.size = Vector2(0, 3)
		cells.add_child(bar)
		bars.append({"bar": bar, "w": track.size.x * maxf(0.0, r["value"])})
	var note: Label = null
	if winners.is_empty():
		note = UI.label("no one has won with this leader", UI.Face.ITALIC, 20, Config.SAND_DIM)
		note.position = Vector2(MARGIN + 32, y + h * 0.5 + 10)
		note.size = Vector2(NAME_W - 40, 26)
		note.modulate.a = 0.0
		add(note)
	return {"placeholder": placeholder, "cells": cells, "bars": bars, "winners": winners,
		"note": note, "name": nm, "y": y, "h": h}


func _reveal(i: int) -> void:
	var c: Dictionary = _rows[i]
	var tw := tween().set_parallel()
	tw.tween_property(c["placeholder"], "modulate:a", 0.0, 0.3)
	tw.tween_property(c["cells"], "modulate:a", 1.0, 0.6).set_delay(0.1)
	if c["note"]:
		# Lift the name to make room for the note beneath it.
		tw.tween_property(c["name"], "position:y", c["y"] - 12, 0.5).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(c["note"], "modulate:a", 1.0, 0.6).set_delay(0.3)
	for b in c["bars"]:
		tw.tween_property(b["bar"], "size:x", b["w"], 1.0).set_delay(0.25) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for p in c["winners"]:
		tw.tween_callback(func():
			add(GoldBurst.new(Rect2(_col_x[p] + 14, c["y"], _col_w - 28, c["h"]), 60))
			_add_point(p)).set_delay(0.5)
	play(tw, func():
		c["placeholder"].modulate.a = 0.0
		c["cells"].modulate.a = 1.0
		if c["note"]:
			c["name"].position.y = c["y"] - 12
			c["note"].modulate.a = 1.0
		for b in c["bars"]:
			b["bar"].size.x = b["w"]
		_sync_points(i))


func _add_point(p: String) -> void:
	_score[p] += 1
	var v: Label = _points[p]
	v.text = str(_score[p])
	v.add_theme_color_override("font_color", Config.GOLD_BRIGHT)
	v.scale = Vector2(1.35, 1.35)
	var tw := tween()
	tw.tween_property(v, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## After a skip: points as they stand once row i is revealed.
func _sync_points(i: int) -> void:
	for p in _score:
		var n := 0
		for j in i + 1:
			if p in _rows[j]["winners"]:
				n += 1
		_score[p] = n
		var v: Label = _points[p]
		v.text = str(n)
		v.scale = Vector2.ONE
		if n > 0:
			v.add_theme_color_override("font_color", Config.GOLD_BRIGHT)
