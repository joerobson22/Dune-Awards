class_name SectionSlide
extends Slide
## A quiet divider between parts of the ceremony.
##   SectionSlide.new("Part two", "The Expansions", "One honour for each box we played")

var eyebrow := ""
var title := ""
var line := ""


func _init(eyebrow_text: String, title_text: String, line_text := "") -> void:
	eyebrow = eyebrow_text
	title = title_text
	line = line_text


func build() -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.size = Vector2(W, H - 80)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add(box)
	box.add_child(UI.eyebrow(eyebrow, 18, Config.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var t := UI.label(title.to_upper(), UI.Face.DISPLAY, 72, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 10)
	t.material = UI.gold_material()
	box.add_child(t)
	var orn := Ornament.new(460, true)
	orn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(orn)
	if line != "":
		box.add_child(UI.label(line, UI.Face.ITALIC, 36, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var i := 0
	for c in box.get_children():
		c.modulate.a = 0.0
		tween().tween_property(c, "modulate:a", 1.0, 0.8).set_delay(0.15 + i * 0.15)
		i += 1
