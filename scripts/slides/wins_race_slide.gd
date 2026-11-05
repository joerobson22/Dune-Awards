class_name WinsRaceSlide
extends RaceSlide
## LISAN AL-GAIB (most wins), with POINTS THE WAY (longest win streak)
## and CHAUMURKY (most tie-breaker wins) told on the same live chart.
##   • A win that extends a streak flashes gold.
##   • A tie-breaker win flashes the colour of the method used.

var _wins := {}
var _run := {}
var _best := {}
var _methods := {}   # player -> Array of win methods (tie-breaks only)


func header_text() -> Array:
	return ["The prophecy fulfilled", "Lisan Al-Gaib",
		"Most wins across all %d games — with Points the Way and Chaumurky" % data.games.size()]


func chart_axis_title() -> String:
	return "Wins"


func chart_series() -> Dictionary:
	var s := {}
	for p in data.players:
		s[p] = [0]
	for g in data.games:
		for p in data.players:
			s[p].append(s[p][-1] + (1 if g["winner"]["player"] == p else 0))
	return s


func table_columns() -> Array:
	return [
		{"key": "wins", "header": "Wins", "width": 110},
		{"key": "streak", "header": "Streak", "width": 126},
		{"key": "ties", "header": "Tie-breaks", "width": 150},
	]


func legend_items() -> Array:
	var items := [{"colour": Config.STREAK_COLOUR, "text": "Streak"}]
	for m in ["Spice", "Solari", "Water", "Chaumurky"]:
		items.append({"colour": Config.METHOD_COLOURS[m], "text": m})
	return items


func reset_state() -> void:
	for p in data.players:
		_wins[p] = 0
		_run[p] = 0
		_best[p] = 0
		_methods[p] = []
		_refresh_row(p)


func apply_game(index: int, live: bool) -> void:
	var g: Dictionary = data.games[index - 1]
	var w: Dictionary = g["winner"]
	var p: String = w["player"]
	var method: String = w["win_method"]
	_wins[p] += 1
	for q in data.players:
		_run[q] = _run[q] + 1 if q == p else 0
		_best[q] = maxi(_best[q], _run[q])
	if method != "VP":
		_methods[p].append(method)
	for q in data.players:
		_refresh_row(q)
	table.sort_by(_wins, live)
	if not live:
		return

	var sub := "%d VP" % w["vp"]
	var sub_colour := Config.SAND_DIM
	if method != "VP":
		var col: Color = Config.METHOD_COLOURS.get(method, Config.SAND)
		sub = "%s tie-break  ·  %d VP" % [method, w["vp"]]
		sub_colour = col
		chart.flash(p, col, "%s TIE-BREAK" % method.to_upper())
		table.flash_cell(p, "ties", col)
	if _run[p] >= 2:
		chart.flash(p, Config.STREAK_COLOUR, "%d IN A ROW" % _run[p])
		table.flash_cell(p, "streak", Config.STREAK_COLOUR)
		if method == "VP":
			sub = "%d in a row  ·  %d VP" % [_run[p], w["vp"]]
			sub_colour = Config.STREAK_COLOUR
	set_ticker(game_line(index), "%s wins as %s" % [data.name_of(p), w["leader"]],
		data.colour_of(p), sub, sub_colour)


func _refresh_row(p: String) -> void:
	table.set_cell(p, "wins", str(_wins[p]))
	table.set_cell(p, "streak", str(_best[p]), "now %d" % _run[p] if _run[p] >= 1 else "")
	table.set_cell(p, "ties", str(_methods[p].size()))
	table.set_dots(p, "ties", _methods[p].map(func(m): return Config.METHOD_COLOURS.get(m, Config.SAND)))


func get_awards() -> Array:
	var vp := data.total_vp()
	var wins := data.wins()
	var most := data.rank(wins, vp)
	var top: Array = most.filter(func(r): return r["rank"] == 1).map(func(r): return r["player"])
	var spans := data.streak_spans()
	var streaks := data.rank(data.longest_streak(), wins)
	var streakers: Array = streaks.filter(func(r): return r["rank"] == 1).map(func(r): return r["player"])
	var s0: Dictionary = spans[streakers[0]]
	var ties := data.rank(data.tiebreak_wins(), wins)
	var tiers: Array = ties.filter(func(r): return r["rank"] == 1).map(func(r): return r["player"])
	var how := {}
	for g in data.games:
		var w: Dictionary = g["winner"]
		if w["player"] == tiers[0] and w["win_method"] != "VP":
			how[w["win_method"]] = how.get(w["win_method"], 0) + 1
	var how_text := []
	for m in how:
		var label: String = m if m == "Chaumurky" else m.to_lower()
		how_text.append("%s ×%d" % [label, how[m]] if how[m] > 1 else label)
	return [
		{"title": "Lisan Al-Gaib", "winners": top,
			"stat": "%s from %d games" % [UI.plural(most[0]["value"], "win"), data.games.size()],
			"note": "Most often victorious as %s" % data.favourite_winning_leader(top[0])},
		{"title": "Points the Way", "winners": streakers,
			"stat": "%d wins in a row" % s0["length"],
			"note": "Games %d to %d, unbroken" % [s0["first"], s0["last"]]},
		{"title": "Chaumurky", "winners": tiers,
			"stat": UI.plural(ties[0]["value"], "tie-breaker win"),
			"note": "Won on " + ", ".join(how_text)},
	]
