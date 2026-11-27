class_name GameData
extends RefCounted
## Loads games.csv, players.csv and core_stats.csv, and answers questions about them.
## Every award reads its numbers from the helpers in the STATS section,
## so a new award usually needs one of these, or a new one beside them.

## Each game: {number, expansion, results: Array[Dictionary], winner: Dictionary}
## Each result: {player, leader, vp, spice, solari, water, chaumurky, winner, win_method}
## Missing tie-break numbers are stored as -1.
var games: Array[Dictionary] = []
var players: Array[String] = []
var display_names := {}
var colours := {}
## Real name -> player tag, from the "person" column of players.csv.
var person_to_player := {}
## The app's per-person stats, in file order:
## [{group, stat, values: {player tag -> String}}]
var core_stats: Array[Dictionary] = []

const _FALLBACK_COLOURS := ["#D9483B", "#4FAE6E", "#5B83E0", "#E6C437", "#C98AD8", "#E0B04A"]


# ════════════════════════════════════════════════════════════════════
#  LOADING
# ════════════════════════════════════════════════════════════════════

## Returns "" on success, or a message describing what went wrong.
func load_all() -> String:
	var err := prepare_data_dir()
	if err != "":
		return err
	err = _load_players(Config.PLAYERS_CSV)
	if err != "":
		return err
	err = _load_games(Config.GAMES_CSV)
	if err != "":
		return err
	return _load_core_stats(Config.CORE_STATS_CSV)


## Makes the data folder, and copies in any CSV it is missing from the
## project's data/ folder. This is how the data moves into a new install.
func prepare_data_dir() -> String:
	DirAccess.make_dir_recursive_absolute(Config.DATA_DIR)
	for path in [Config.PLAYERS_CSV, Config.GAMES_CSV, Config.CORE_STATS_CSV]:
		if FileAccess.file_exists(path):
			continue
		var source: String = Config.SEED_DIR + path.get_file()
		if not FileAccess.file_exists(source):
			continue
		var out := FileAccess.open(path, FileAccess.WRITE)
		if out == null:
			return "Could not create %s (%s)." % [data_folder().path_join(path.get_file()),
				error_string(FileAccess.get_open_error())]
		out.store_buffer(FileAccess.get_file_as_bytes(source))
		out.close()
	return ""


## Where the data folder is on this computer, as a normal path.
static func data_folder() -> String:
	return ProjectSettings.globalize_path(Config.DATA_DIR)


## Replaces a data file in one go: writes a temporary copy, then swaps it in,
## so a crash part-way through can never leave half a file.
func _write_file(path: String, text: String) -> String:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return "Could not save %s (%s)." % [path.get_file(), error_string(FileAccess.get_open_error())]
	f.store_string(text)
	f.close()
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK and FileAccess.file_exists(path):
		# Some systems won't rename over an existing file.
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		return "Could not save %s (%s)." % [path.get_file(), error_string(err)]
	return ""


func _read_csv(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var header := f.get_csv_line()
	for i in header.size():
		header[i] = header[i].strip_edges().to_lower()
	var rows := []
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() == 1 and line[0].strip_edges() == "":
			continue
		var row := {}
		for i in header.size():
			row[header[i]] = line[i].strip_edges() if i < line.size() else ""
		rows.append(row)
	return rows


func _load_players(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""  # optional: tags are used as names and colours are picked
	for row in _read_csv(path):
		var tag: String = row.get("player", "")
		if tag == "":
			continue
		players.append(tag)
		var shown: String = row.get("display_name", "")
		display_names[tag] = shown if shown != "" else tag
		var person: String = row.get("person", "")
		if person != "":
			person_to_player[person] = tag
		var hex: String = row.get("colour", row.get("color", ""))
		if hex != "" and Color.html_is_valid(hex):
			colours[tag] = Color.html(hex)
	return ""


func _load_games(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "Could not find %s" % path
	var by_number := {}
	var line_no := 1
	for row in _read_csv(path):
		line_no += 1
		if not row.get("game", "").is_valid_int() or not row.get("vp", "").is_valid_int():
			return "games.csv line %d: 'game' and 'vp' must be whole numbers." % line_no
		var n := int(row["game"])
		var tag: String = row.get("player", "")
		if tag == "":
			return "games.csv line %d: the player column is empty." % line_no
		if not by_number.has(n):
			by_number[n] = {"number": n, "expansion": row.get("expansion", ""), "results": [], "winner": {}}
		by_number[n]["results"].append({
			"player": tag,
			"leader": row.get("leader", ""),
			"vp": int(row["vp"]),
			"spice": _num(row.get("spice", "")),
			"solari": _num(row.get("solari", "")),
			"water": _num(row.get("water", "")),
			"chaumurky": row.get("chaumurky", "") in ["1", "yes", "true", "y"],
			"winner": row.get("winner", "") in ["1", "yes", "true", "y"],
			"win_method": row.get("win_method", ""),
		})
		if tag not in players:
			players.append(tag)
	var numbers := by_number.keys()
	numbers.sort()
	for n in numbers:
		var g: Dictionary = by_number[n]
		var marked: Array = g["results"].filter(func(r): return r["winner"])
		if marked.is_empty():
			_decide_winner(g)
		else:
			g["winner"] = marked[0]
			if g["winner"]["win_method"] == "":
				g["winner"]["win_method"] = "VP"
		games.append(g)
	for i in players.size():
		var tag := players[i]
		if not display_names.has(tag):
			display_names[tag] = tag
		if not colours.has(tag):
			colours[tag] = Color.html(_FALLBACK_COLOURS[i % _FALLBACK_COLOURS.size()])
	if games.is_empty():
		return "games.csv has no games in it."
	return ""


## core_stats.csv: person,group,stat,value — one row per person per stat.
## People are matched to player tags through players.csv.
func _load_core_stats(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""  # optional
	var by_stat := {}
	for row in _read_csv(path):
		var person: String = row.get("person", "")
		var tag: String = person_to_player.get(person, "")
		if tag == "":
			return "core_stats.csv: '%s' has no matching player. Add them to the person column of players.csv." % person
		var stat: String = row.get("stat", "")
		if not by_stat.has(stat):
			by_stat[stat] = {"group": row.get("group", ""), "stat": stat, "values": {}}
			core_stats.append(by_stat[stat])
		by_stat[stat]["values"][tag] = row.get("value", "")
	return ""


func _num(s: String) -> int:
	return int(s) if s.is_valid_int() else -1


## Applies the game's rules when no winner is marked in the CSV.
func _decide_winner(g: Dictionary) -> void:
	var d := decide_winner(g["results"])
	var w: Dictionary = g["results"][d["index"]]
	w["winner"] = true
	w["win_method"] = d["method"]
	g["winner"] = w


## The game's rules: most VPs, then Chaumurky, then spice, solari and
## water. `results` is one game's rows ({vp, chaumurky, spice, solari,
## water}, -1 for a blank number). Returns {index, method}.
func decide_winner(results: Array) -> Dictionary:
	var top: int = results.map(func(r): return r["vp"]).max()
	var tied: Array = range(results.size()).filter(func(i): return results[i]["vp"] == top)
	var method := "VP"
	if tied.size() > 1:
		var holder: Array = tied.filter(func(i): return results[i]["chaumurky"])
		if not holder.is_empty():
			tied = holder
			method = "Chaumurky"
		else:
			for key in Config.TIEBREAK_ORDER:
				if tied.size() == 1:
					break
				var best: int = tied.map(func(i): return results[i][key]).max()
				tied = tied.filter(func(i): return results[i][key] == best)
				method = key.capitalize()
	return {"index": tied[0], "method": method}


## Which tie-break numbers a new game needs, following decide_winner().
## Returns [{index, key, required}]: `required` is true when the number
## decides the winner, false when it only splits a lower place.
## Every row needs a vp first.
func tiebreak_requests(results: Array) -> Array:
	var out := []
	var by_vp := {}
	for i in results.size():
		by_vp[results[i]["vp"]] = by_vp.get(results[i]["vp"], []) + [i]
	var top: int = by_vp.keys().max()
	for vp in by_vp:
		var group: Array = by_vp[vp]
		if group.size() < 2:
			continue
		var deciding: bool = vp == top
		var holder: Array = group.filter(func(i): return results[i]["chaumurky"])
		if deciding and not holder.is_empty():
			group = group.filter(func(i): return i not in holder)
			deciding = false
		_split_tie(results, group, 0, deciding, out)
	return out


func _split_tie(results: Array, group: Array, depth: int, deciding: bool, out: Array) -> void:
	if group.size() < 2 or depth >= Config.TIEBREAK_ORDER.size():
		return
	var key: String = Config.TIEBREAK_ORDER[depth]
	for i in group:
		out.append({"index": i, "key": key, "required": deciding})
	if group.any(func(i): return results[i][key] < 0):
		return  # the next number is only asked once this one is filled in
	var by_value := {}
	for i in group:
		by_value[results[i][key]] = by_value.get(results[i][key], []) + [i]
	var best: int = by_value.keys().max()
	for v in by_value:
		_split_tie(results, by_value[v], depth + 1, deciding and v == best, out)


## Adds a game to the end of games.csv. `rows`: one per player,
## {player, leader, vp, spice, solari, water, chaumurky} (-1 = blank).
## The winner is worked out by decide_winner(). Returns "" on success.
## Reload the data afterwards (main.gd does) to see it everywhere.
func append_game(expansion: String, rows: Array) -> String:
	var path := Config.GAMES_CSV
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		return "Could not open %s for writing (%s)." \
			% [data_folder().path_join(path.get_file()), error_string(FileAccess.get_open_error())]
	var n := next_game_number()
	var d := decide_winner(rows)
	var length := f.get_length()
	if length > 0:
		f.seek(length - 1)
		var ends_cleanly := f.get_8() == 10
		f.seek_end()
		if not ends_cleanly:
			f.store_string("\n")
	for i in rows.size():
		var r: Dictionary = rows[i]
		var won: bool = i == d["index"]
		f.store_csv_line(PackedStringArray([str(n), expansion, r["player"], r["leader"],
			str(r["vp"]), _cell(r["spice"]), _cell(r["solari"]), _cell(r["water"]),
			"1" if r["chaumurky"] else "0", "1" if won else "0", d["method"] if won else ""]))
	f.close()
	return ""


## Saves every core stat back to core_stats.csv, in the same layout:
## one row per person per stat, stat by stat. `stats` is the same shape as
## `core_stats`: [{group, stat, values: {player tag -> String}}].
## Returns "" on success. Reload the data afterwards to see it.
func save_core_stats(stats: Array) -> String:
	var person_of := {}
	for person in person_to_player:
		person_of[person_to_player[person]] = person
	var lines := PackedStringArray(["person,group,stat,value"])
	for s in stats:
		for p in players:
			if not s["values"].has(p) or not person_of.has(p):
				continue
			lines.append(",".join([_csv(person_of[p]), _csv(s["group"]), _csv(s["stat"]),
				_csv(s["values"][p])]))
	return _write_file(Config.CORE_STATS_CSV, "\n".join(lines) + "\n")


## Quotes a CSV cell if it needs it.
func _csv(v: String) -> String:
	if v.contains(",") or v.contains("\"") or v.contains("\n"):
		return "\"%s\"" % v.replace("\"", "\"\"")
	return v


func _cell(v: int) -> String:
	return str(v) if v >= 0 else ""


# ════════════════════════════════════════════════════════════════════
#  STATS — each returns a Dictionary of player tag -> value
#  Pass an expansion code ("Base", "IX", ...) to look at one box only.
# ════════════════════════════════════════════════════════════════════

func games_in(expansion := "") -> Array[Dictionary]:
	if expansion == "":
		return games
	var out: Array[Dictionary] = []
	for g in games:
		if g["expansion"] == expansion:
			out.append(g)
	return out


func _zeroes() -> Dictionary:
	var d := {}
	for p in players:
		d[p] = 0
	return d


func wins(expansion := "") -> Dictionary:
	var d := _zeroes()
	for g in games_in(expansion):
		d[g["winner"]["player"]] += 1
	return d


func total_vp(expansion := "") -> Dictionary:
	var d := _zeroes()
	for g in games_in(expansion):
		for r in g["results"]:
			d[r["player"]] += r["vp"]
	return d


## Wins that came from a tie-break (spice, solari, water or Chaumurky).
func tiebreak_wins(expansion := "") -> Dictionary:
	var d := _zeroes()
	for g in games_in(expansion):
		if g["winner"]["win_method"] != "VP":
			d[g["winner"]["player"]] += 1
	return d


## Longest run of consecutive wins.
func longest_streak(expansion := "") -> Dictionary:
	var best := _zeroes()
	var run := _zeroes()
	for g in games_in(expansion):
		var w: String = g["winner"]["player"]
		for p in players:
			run[p] = run[p] + 1 if p == w else 0
			best[p] = maxi(best[p], run[p])
	return best


## Where each player's longest streak happened: {length, first, last}
## with game numbers. The earliest streak wins when two are equal.
func streak_spans(expansion := "") -> Dictionary:
	var out := {}
	var start := {}
	var run := _zeroes()
	for p in players:
		out[p] = {"length": 0, "first": 0, "last": 0}
	for g in games_in(expansion):
		var w: String = g["winner"]["player"]
		for p in players:
			if p == w:
				if run[p] == 0:
					start[p] = g["number"]
				run[p] += 1
				if run[p] > out[p]["length"]:
					out[p] = {"length": run[p], "first": start[p], "last": g["number"]}
			else:
				run[p] = 0
	return out


## Finishing place of every player in a game (1 = winner). Players are
## ordered by VP, then the winner, then spice, solari and water. Anyone
## still level shares the better place.
func placements(g: Dictionary) -> Dictionary:
	var keyed := []
	for r in g["results"]:
		keyed.append({"player": r["player"], "key": [r["vp"], 1 if r["winner"] else 0,
			r["spice"], r["solari"], r["water"]]})
	var out := {}
	for a in keyed:
		var better := 0
		for b in keyed:
			if _key_greater(b["key"], a["key"]):
				better += 1
		out[a["player"]] = better + 1
	return out


func _key_greater(a: Array, b: Array) -> bool:
	for i in a.size():
		if a[i] != b[i]:
			return a[i] > b[i]
	return false


## How many times each player finished in a given place (e.g. 4 = last).
func finishes(place: int, expansion := "") -> Dictionary:
	var d := _zeroes()
	for g in games_in(expansion):
		var pl := placements(g)
		for p in pl:
			if pl[p] == place:
				d[p] += 1
	return d


## Each player's lowest VP score in a game: {vp, leader, game} (first time).
func lowest_game_of(player: String, expansion := "") -> Dictionary:
	var out := {}
	for g in games_in(expansion):
		for r in g["results"]:
			if r["player"] == player and (out.is_empty() or r["vp"] < out["vp"]):
				out = {"vp": r["vp"], "leader": r["leader"], "game": g["number"]}
	return out


## Games played and won with one leader: player -> {plays, wins}.
func leader_record(leader: String, expansion := "") -> Dictionary:
	var d := {}
	for p in players:
		d[p] = {"plays": 0, "wins": 0}
	for g in games_in(expansion):
		for r in g["results"]:
			if r["leader"] == leader:
				d[r["player"]]["plays"] += 1
				if r["winner"]:
					d[r["player"]]["wins"] += 1
	return d


func next_game_number() -> int:
	return games[-1]["number"] + 1 if not games.is_empty() else 1


## Every leader played, A to Z.
func leaders() -> Array[String]:
	var out: Array[String] = []
	for g in games:
		for r in g["results"]:
			if r["leader"] != "" and r["leader"] not in out:
				out.append(r["leader"])
	out.sort()
	return out


## Wins with each leader, most first: [{leader, wins, plays, winners}]
## where `winners` lists the player tag of each win, in game order.
## Level leaders are ordered by fewer plays (the better rate), then A–Z.
func leader_table(expansion := "") -> Array:
	var by := {}
	for g in games_in(expansion):
		for r in g["results"]:
			var l: String = r["leader"]
			if not by.has(l):
				by[l] = {"leader": l, "wins": 0, "plays": 0, "winners": []}
			by[l]["plays"] += 1
			if r["winner"]:
				by[l]["wins"] += 1
				by[l]["winners"].append(r["player"])
	var rows := by.values()
	rows.sort_custom(func(a, b):
		if a["wins"] != b["wins"]:
			return a["wins"] > b["wins"]
		if a["plays"] != b["plays"]:
			return a["plays"] < b["plays"]
		return a["leader"] < b["leader"])
	return rows


## The highest VPs anyone scored in one game: {vp, player, leader, game}.
## The first time it happened wins a tie.
func biggest_finish(expansion := "") -> Dictionary:
	var out := {}
	for g in games_in(expansion):
		for r in g["results"]:
			if out.is_empty() or r["vp"] > out["vp"]:
				out = {"vp": r["vp"], "player": r["player"], "leader": r["leader"], "game": g["number"]}
	return out


## Highest VPs in a single game.
func best_single_game(expansion := "") -> Dictionary:
	var d := _zeroes()
	for g in games_in(expansion):
		for r in g["results"]:
			d[r["player"]] = maxi(d[r["player"]], r["vp"])
	return d


## Number of games where a player chose a given leader.
func leader_plays(leader: String, expansion := "") -> Dictionary:
	var d := _zeroes()
	for g in games_in(expansion):
		for r in g["results"]:
			if r["leader"] == leader:
				d[r["player"]] += 1
	return d


## Number of games a player won with a given leader.
func leader_wins(leader: String, expansion := "") -> Dictionary:
	var d := _zeroes()
	for g in games_in(expansion):
		for r in g["results"]:
			if r["leader"] == leader and r["winner"]:
				d[r["player"]] += 1
	return d


## The leader a player won with most often (ties go to the earlier win).
func favourite_winning_leader(player: String, expansion := "") -> String:
	var counts := {}
	var best := ""
	for g in games_in(expansion):
		var w: Dictionary = g["winner"]
		if w["player"] != player:
			continue
		counts[w["leader"]] = counts.get(w["leader"], 0) + 1
		if best == "" or counts[w["leader"]] > counts[best]:
			best = w["leader"]
	return best


## The game a player scored their best single-game VPs in (first time).
func best_game_of(player: String, expansion := "") -> Dictionary:
	var out := {}
	for g in games_in(expansion):
		for r in g["results"]:
			if r["player"] == player and (out.is_empty() or r["vp"] > out["vp"]):
				out = {"vp": r["vp"], "leader": r["leader"], "game": g["number"]}
	return out


# ════════════════════════════════════════════════════════════════════
#  RANKING
# ════════════════════════════════════════════════════════════════════

## Sorts players by value (highest first), then by an optional
## tie-break Dictionary. Players level on both share a rank.
## Returns [{player, value, tiebreak, rank}].
func rank(values: Dictionary, tiebreak := {}) -> Array:
	var rows := []
	for p in players:
		rows.append({"player": p, "value": values.get(p, 0), "tiebreak": tiebreak.get(p, 0)})
	rows.sort_custom(func(a, b):
		if a["value"] != b["value"]:
			return a["value"] > b["value"]
		return a["tiebreak"] > b["tiebreak"])
	for i in rows.size():
		var same: bool = i > 0 and rows[i]["value"] == rows[i - 1]["value"] \
				and rows[i]["tiebreak"] == rows[i - 1]["tiebreak"]
		rows[i]["rank"] = rows[i - 1]["rank"] if same else i + 1
	return rows


## Everyone sharing the top spot of a ranking, joined as "A & B".
func winners_text(ranking: Array) -> String:
	var names := []
	for r in ranking:
		if r["rank"] == 1:
			names.append(name_of(r["player"]))
	return " & ".join(names)


func name_of(player: String) -> String:
	return display_names.get(player, player)


func colour_of(player: String) -> Color:
	return colours.get(player, Config.SAND)


func expansion_name(code: String) -> String:
	return Config.EXPANSIONS.get(code, code)


## Expansions in play order, with the game span each one covers.
## Returns [{code, name, first, last}] using positions in `games` (1-based).
func expansion_spans() -> Array:
	var spans := []
	for i in games.size():
		var code: String = games[i]["expansion"]
		if spans.is_empty() or spans[-1]["code"] != code:
			spans.append({"code": code, "name": expansion_name(code), "first": i + 1, "last": i + 1})
		else:
			spans[-1]["last"] = i + 1
	return spans
