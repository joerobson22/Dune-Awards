class_name TitleSlide
extends Slide
## The opening slide. Pass a different tagline to change the line
## under the title, e.g. TitleSlide.new("Two years on Arrakis").

var tagline := ""


func _init(line := "") -> void:
	tagline = line


func build() -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.position = Vector2(0, 0)
	box.size = Vector2(W, H - 80)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add(box)

	box.add_child(UI.eyebrow("A ceremony of the Imperium", 18, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UI.label("THE", UI.Face.DISPLAY, 30, Config.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 14))
	var title := UI.label("DUNE AWARDS", UI.Face.DISPLAY, 104, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 14)
	title.material = UI.gold_material()
	box.add_child(title)
	var orn := Ornament.new(620, true)
	orn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(orn)

	var expansions := data.expansion_spans().size()
	var line := tagline
	if line == "":
		line = "%d games  ·  %s  ·  %d contenders" % [data.games.size(),
			UI.plural(expansions, "expansion"), data.players.size()]
	var tl := UI.label(line, UI.Face.ITALIC, 38, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(tl)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 40)
	box.add_child(gap)

	var names := HBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 72)
	for p in data.players:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.add_child(UI.label(data.name_of(p), UI.Face.SERIF_BOLD, 44, Config.SAND, HORIZONTAL_ALIGNMENT_CENTER))
		var bar := ColorRect.new()
		bar.color = data.colour_of(p)
		bar.custom_minimum_size = Vector2(0, 3)
		col.add_child(bar)
		names.add_child(col)
	box.add_child(names)

	var hint := UI.eyebrow("Click to begin", 14, Config.SAND_FAINT, HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(0, H - 150)
	hint.size = Vector2(W, 24)
	add(hint)
	var tw := tween().set_loops()
	tw.tween_property(hint, "modulate:a", 0.35, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(hint, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)

	# Fade the parts in one after another.
	var i := 0
	for c in box.get_children():
		c.modulate.a = 0.0
		tween().tween_property(c, "modulate:a", 1.0, 0.9).set_delay(0.25 + i * 0.18)
		i += 1
