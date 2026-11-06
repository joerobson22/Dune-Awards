class_name Awards
extends RefCounted
## ════════════════════════════════════════════════════════════════════
##  ★ THE RUNNING ORDER ★
##  Every slide in the ceremony, top to bottom. To add an award, add a
##  line to this list. To drop or reorder one, move or delete its line.
##  README.md has worked examples.
## ════════════════════════════════════════════════════════════════════

static func running_order(data: GameData) -> Array[Slide]:
	return [
		TitleSlide.new(),

		SectionSlide.new("Part one", "The players",
			"Loyalties, misfortunes and the minds behind the moves"),
		FaveAllianceSlide.new(),  # one column per alliance, revealed in turn
		SillyAwardsSlide.new([
			{"eyebrow": "Fed to the worm", "title": "Most 4th places",
				"values": data.finishes(4), "unit": "4th place"},
			{"eyebrow": "So near, so far", "title": "Most 3rd places",
				"values": data.finishes(3), "unit": "3rd place"},
			{"eyebrow": "A bad day on Arrakis", "title": "Lowest VP finish",
				"values": _lowest_vp(data), "unit": "victory point", "lowest_wins": true,
				"detail": func(p): return _lowest_detail(data, p)},
		]),
		CoreStatsSlide.new({     # Muad'Dib: a point per core stat
			"labels": {
				"Avg. SMF": "Spice Must Flow",
				"Avg. Spice Remaining": "Spice left over",
				"% Games w/ SM": "Games with Swordmaster",
				"% Games w/ HC": "Games with High Council",
			},
			"lower_wins": [],
		}),
		LeaderAwardsSlide.new(["Baron", "Leto", "Paul", "Rabban"]),  # Dune 1 award

		SectionSlide.new("Part two", "The long war",
			"Honours earned across every game we have played"),
		WinsRaceSlide.new(),      # Lisan Al-Gaib · Points the Way · Chaumurky
		VpRaceSlide.new(),        # Shai Hulud · Treachery

		SectionSlide.new("Part three", "The four boxes",
			"One honour for each era of the Imperium"),
		_mode_award(data, "Base", "Duke of Arrakis"),
		_mode_award(data, "IX", "Leader of IX"),
		_mode_award(data, "Immortality", "Tleilax Master"),
		_mode_award(data, "Uprising", "Imperium Lord"),

		# ── Add new award slides here ──────────────────────────────
		# RankingRevealSlide.new({
		#     "eyebrow": "The Harkonnen way",
		#     "title": "Na-Baron",
		#     "subtitle": "Most games played as the Baron",
		#     "values": data.leader_plays("Baron"),
		#     "unit": "game",
		# }),
		# ───────────────────────────────────────────────────────────

		FinaleSlide.new(),
	]


## Most wins in one expansion, revealed 4th to 1st. Level scores are
## split by total VPs in that expansion.
static func _mode_award(data: GameData, code: String, title: String) -> RankingRevealSlide:
	var n := data.games_in(code).size()
	var vp := data.total_vp(code)
	return RankingRevealSlide.new({
		"eyebrow": data.expansion_name(code),
		"title": title,
		"subtitle": "Most wins in %s  ·  %s played" % [data.expansion_name(code), UI.plural(n, "game")],
		"values": data.wins(code),
		"unit": "win",
		"tiebreak": vp,
		"tiebreak_name": "total VP",
		"detail": func(p): return _mode_detail(data, code, vp, p),
	})


static func _mode_detail(data: GameData, code: String, vp: Dictionary, p: String) -> String:
	var n := data.games_in(code).size()
	var fav := data.favourite_winning_leader(p, code)
	var line := "%d VP across %s" % [vp[p], UI.plural(n, "game")]
	return line + ("  ·  most wins as %s" % fav if fav != "" else "")


static func _lowest_vp(data: GameData) -> Dictionary:
	var d := {}
	for p in data.players:
		d[p] = data.lowest_game_of(p)["vp"]
	return d


static func _lowest_detail(data: GameData, p: String) -> String:
	var g := data.lowest_game_of(p)
	return "as %s, game %d" % [g["leader"], g["game"]]
