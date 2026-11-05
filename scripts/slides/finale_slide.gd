class_name FinaleSlide
extends Slide
## The closing slide: every award handed out tonight, gathered from
## each slide's get_awards(). New awards appear here automatically.

func build() -> void:
	var top := add_header("The honours of the Imperium", "The spice must flow",
		"Every award, and who took it home") + 34.0
	var awards := []
	for s in ceremony:
		awards.append_array(s.get_awards())
	if awards.is_empty():
		return
	var cols := 3 if awards.size() > 4 else 2
	var rows := ceili(awards.size() / float(cols))
	var gap := 24.0
	var card_w := (W - MARGIN * 2 - gap * (cols - 1)) / cols
	var card_h := minf(190.0, (H - 100.0 - top - gap * (rows - 1)) / rows)
	for i in awards.size():
		var a: Dictionary = awards[i]
		var r := Rect2(MARGIN + (i % cols) * (card_w + gap), top + (i / cols) * (card_h + gap), card_w, card_h)
		var card := UI.panel(r)
		add(card)
		var t := UI.eyebrow(a["title"], 15, Config.GOLD)
		t.position = Vector2(30, card_h * 0.5 - 62)
		t.size = Vector2(card_w - 60, 24)
		card.add_child(t)
		var names := " & ".join(a["winners"].map(func(p): return data.name_of(p)))
		var n := UI.label(names, UI.Face.SERIF_BOLD, 48, Config.SAND)
		n.position = Vector2(28, card_h * 0.5 - 38)
		n.size = Vector2(card_w - 60, 60)
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(n)
		var bar := ColorRect.new()
		bar.color = data.colour_of(a["winners"][0])
		bar.position = Vector2(0, 0)
		bar.size = Vector2(3, card_h)
		card.add_child(bar)
		var s := UI.label(a.get("stat", ""), UI.Face.ITALIC, 27, Config.SAND_DIM)
		s.position = Vector2(30, card_h * 0.5 + 24)
		s.size = Vector2(card_w - 60, 36)
		s.clip_text = true
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(s)
		card.modulate.a = 0.0
		tween().tween_property(card, "modulate:a", 1.0, 0.6).set_delay(0.3 + i * 0.12)
