class_name KwisatzSlide
extends RankingRevealSlide

func _init() -> void:
	super({"eyebrow": "He who sees possible realities all at once",
		"title": "Kwisatz Haderach",
		"subtitle": "Most honours won tonight", "unit": "honour"})

func _rank() -> Array:
	var tally := {}
	for p in data.players:
		tally[p] = 0
	for s in ceremony:
		if s == self:
			continue
		for a in s.get_awards():
			for p in a["winners"]:
				tally[p] += 1
	opts["values"] = tally
	opts["tiebreak"] = data.total_vp()
	opts["tiebreak_name"] = "total VP"
	return super()
