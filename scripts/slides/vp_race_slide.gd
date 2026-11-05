class_name VpRaceSlide
extends RaceSlide
## SHAI HULUD (most total VPs) with TREACHERY (most VPs in one game)
## on the same live chart. A new single-game record flashes red.

var _total := {}
var _played := {}
var _best := {}       # player -> {vp, leader, game}
var _record := 0


func header_text() -> Array:
	return ["The great maker", "Shai Hulud",
		"Most victory points across every game — with Treachery, the greatest single game"]


func chart_axis_title() -> String:
	return "Total victory points"


func chart_series() -> Dictionary:
	var s := {}
	for p in data.players:
		s[p] = [0]
	for g in data.games:
		var got := {}
		for r in g["results"]:
			got[r["player"]] = r["vp"]
		for p in data.players:
			s[p].append(s[p][-1] + got.get(p, 0))
	return s


func table_columns() -> Array:
	return [
		{"key": "total", "header": "Total VP", "width": 132},
		{"key": "avg", "header": "Average", "width": 116},
		{"key": "best", "header": "Best game", "width": 142},
	]


func legend_items() -> Array:
	return [{"colour": Config.RECORD_COLOUR, "text": "New single-game record (Treachery)"}]


func reset_state() -> void:
	_record = 0
	for p in data.players:
		_total[p] = 0
		_played[p] = 0
		_best[p] = {"vp": 0, "leader": "", "game": 0}
		_refresh_row(p)


func apply_game(index: int, live: bool) -> void:
	var g: Dictionary = data.games[index - 1]
	var top: Dictionary = {}
	for r in g["results"]:
		var p: String = r["player"]
		_total[p] += r["vp"]
		_played[p] += 1
		if r["vp"] > _best[p]["vp"]:
			_best[p] = {"vp": r["vp"], "leader": r["leader"], "game": g["number"]}
		if top.is_empty() or r["vp"] > top["vp"]:
			top = r
	for p in data.players:
		_refresh_row(p)
	table.sort_by(_total, live)
	var broke: bool = top["vp"] > _record
	if broke:
		_record = top["vp"]
	if not live:
		return
	var w: Dictionary = g["winner"]
	if broke:
		chart.flash(top["player"], Config.RECORD_COLOUR, "NEW RECORD · %d VP" % top["vp"])
		table.flash_cell(top["player"], "best", Config.RECORD_COLOUR)
		set_ticker(game_line(index), "%s scores %d as %s" % [data.name_of(top["player"]), top["vp"], top["leader"]],
			data.colour_of(top["player"]), "A new single-game record", Config.RECORD_COLOUR)
	else:
		var second := 0
		for r in g["results"]:
			if r != w:
				second = maxi(second, r["vp"])
		var margin := "by %s" % UI.plural(w["vp"] - second, "point") if w["vp"] > second else "on a tie-break"
		set_ticker(game_line(index), "%s wins with %d VP" % [data.name_of(w["player"]), w["vp"]],
			data.colour_of(w["player"]), "As %s, %s" % [w["leader"], margin])


func _refresh_row(p: String) -> void:
	table.set_cell(p, "total", str(_total[p]))
	var avg := "–" if _played[p] == 0 else "%.1f" % (float(_total[p]) / _played[p])
	table.set_cell(p, "avg", avg)
	var b: Dictionary = _best[p]
	table.set_cell(p, "best", str(b["vp"]), "" if b["game"] == 0 else "%s · G%d" % [b["leader"], b["game"]])


func get_awards() -> Array:
	var wins := data.wins()
	var totals := data.rank(data.total_vp(), wins)
	var top: Array = totals.filter(func(r): return r["rank"] == 1).map(func(r): return r["player"])
	var single := data.rank(data.best_single_game())
	var traitors: Array = single.filter(func(r): return r["rank"] == 1).map(func(r): return r["player"])
	var bg := data.best_game_of(traitors[0])
	var g: Dictionary = data.games.filter(func(x): return x["number"] == bg["game"])[0]
	return [
		{"title": "Shai Hulud", "winners": top,
			"stat": "%d victory points" % totals[0]["value"],
			"note": "An average of %.1f a game, over %d games" % [float(totals[0]["value"]) / _games_played(top[0]), _games_played(top[0])]},
		{"title": "Treachery", "winners": traitors,
			"stat": "%d VP in a single game" % single[0]["value"],
			"note": "As %s, in game %d (%s)" % [bg["leader"], bg["game"], data.expansion_name(g["expansion"])]},
	]


func _games_played(p: String) -> int:
	var n := 0
	for g in data.games:
		for r in g["results"]:
			if r["player"] == p:
				n += 1
	return n
