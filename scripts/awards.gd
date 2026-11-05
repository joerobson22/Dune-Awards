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

		SectionSlide.new("Part one", "The long war",
			"Honours earned across every game we have played"),
		WinsRaceSlide.new(),      # Lisan Al-Gaib · Points the Way · Chaumurky
		VpRaceSlide.new(),        # Shai Hulud · Treachery

		SectionSlide.new("Part two", "The four boxes",
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
