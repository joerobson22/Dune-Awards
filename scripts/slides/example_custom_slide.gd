class_name ExampleCustomSlide
extends Slide
## ════════════════════════════════════════════════════════════════════
##  TEMPLATE for an award with its own look. Copy this file, rename the
##  class, change the bits marked ✎, then add  MyNewSlide.new()  to the
##  list in scripts/awards.gd.
##
##  This example: "Mentat" — the best average VPs per game, shown as
##  bars that grow one click at a time, then the award card.
##  (For a plain 4th-to-1st reveal you don't need a new file at all:
##  use RankingRevealSlide in awards.gd.)
## ════════════════════════════════════════════════════════════════════

var _bars := []


## ✎ The score for each player: player tag -> number.
func _scores() -> Dictionary:
	var totals := data.total_vp()
	var out := {}
	for p in data.players:
		out[p] = float(totals[p]) / data.games.size()
	return out


## ✎ What the finale (and the award card) shows.
func get_awards() -> Array:
	var ranking := data.rank(_scores())
	var winners := ranking.filter(func(r): return r["rank"] == 1).map(func(r): return r["player"])
	return [{"title": "Mentat", "winners": winners,
		"stat": "%.1f VP a game on average" % ranking[0]["value"]}]


func build() -> void:
	# ✎ The heading.
	var top := add_header("The thinking machine", "Mentat", "The best average victory points per game") + 60.0

	var scores := _scores()
	var best: float = scores.values().max()
	var y := top
	for p in data.players:
		var name_l := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, 44, Config.SAND)
		name_l.position = Vector2(MARGIN, y)
		name_l.size = Vector2(380, 70)
		add(name_l)
		var bar := ColorRect.new()
		bar.color = data.colour_of(p)
		bar.position = Vector2(MARGIN + 400, y + 26)
		bar.size = Vector2(0, 18)
		add(bar)
		var value_l := UI.label("", UI.Face.NUMBER, 32, Config.SAND)
		value_l.position = Vector2(MARGIN + 400, y)
		value_l.size = Vector2(200, 70)
		add(value_l)
		_bars.append({"bar": bar, "label": value_l, "width": 1000.0 * scores[p] / best, "score": scores[p]})
		y += 100.0

	# Click 1: grow every bar. Click 2: the award card.
	add_step(_grow)
	add_award_card_steps(get_awards())


func _grow() -> void:
	var tw := tween().set_parallel()
	for b in _bars:
		tw.tween_property(b["bar"], "size:x", b["width"], 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(b["label"], "position:x", MARGIN + 420 + b["width"], 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		b["label"].text = "%.1f" % b["score"]
	# play() lets a click finish the animation instead of skipping ahead.
	play(tw, func():
		for b in _bars:
			b["bar"].size.x = b["width"]
			b["label"].position.x = MARGIN + 420 + b["width"])
