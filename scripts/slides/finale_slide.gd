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
	var cols := 4 if awards.size() > 12 else (3 if awards.size() > 4 else 2)
	var rows := ceili(awards.size() / float(cols))
	var gap := 24.0 if cols < 4 else 16.0
	var card_w := (W - MARGIN * 2 - gap * (cols - 1)) / cols
	var card_h := minf(190.0, (H - 100.0 - top - gap * (rows - 1)) / rows)
	# Many awards: a tighter card with smaller type.
	var compact := card_h < 160.0
	var eyebrow_px := 12 if compact else 15
	var name_px := 34 if compact else 48
	var stat_px := 21 if compact else 27
	var name_h := UI.font(UI.Face.SERIF_BOLD).get_height(name_px)
	var stat_h := UI.font(UI.Face.ITALIC).get_height(stat_px)
	var block := 22.0 + name_h + stat_h - 10.0
	var y0 := (card_h - block) * 0.5
	for i in awards.size():
		var a: Dictionary = awards[i]
		var r := Rect2(MARGIN + (i % cols) * (card_w + gap), top + (i / cols) * (card_h + gap), card_w, card_h)
		var card := UI.panel(r)
		add(card)
		var pad := 22.0 if compact else 30.0
		var t := UI.eyebrow(a["title"], eyebrow_px, Config.GOLD)
		t.position = Vector2(pad, y0)
		t.size = Vector2(card_w - pad * 2, 20)
		t.clip_text = true
		card.add_child(t)
		var names := " & ".join(a["winners"].map(func(p): return data.name_of(p)))
		var n := UI.label(names, UI.Face.SERIF_BOLD, name_px, Config.SAND)
		n.position = Vector2(pad - 2, y0 + 22.0)
		n.size = Vector2(card_w - pad * 2, name_h)
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(n)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 0)
		vb.size = Vector2(3, card_h)
		for p in a["winners"]:
			var bar := ColorRect.new()
			bar.color = data.colour_of(p)
			bar.custom_minimum_size = Vector2(3, 0)
			bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vb.add_child(bar)
		card.add_child(vb)
		var s := UI.label(a.get("stat", ""), UI.Face.ITALIC, stat_px, Config.SAND_DIM)
		s.position = Vector2(pad, y0 + 22.0 + name_h - 10.0)
		s.size = Vector2(card_w - pad * 2, stat_h)
		s.clip_text = true
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(s)
		card.modulate.a = 0.0
		tween().tween_property(card, "modulate:a", 1.0, 0.6).set_delay(0.3 + i * 0.07)
