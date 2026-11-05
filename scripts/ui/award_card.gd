class_name AwardCard
extends Control
## The winner's card that rises over a slide. Call show_award() with:
##   {title, winners: [player tags], stat, note}
## Calling it again swaps to the next award on the same card.

const CARD_SIZE := Vector2(1160, 600)

var data: GameData
var _dim: ColorRect
var _card: Panel
var _box: VBoxContainer


func _init(game_data: GameData) -> void:
	data = game_data


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.72)
	_dim.size = size
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	var st := UI.panel_style(Config.GOLD, 0.8, 0.97)
	st.set_border_width_all(2)
	st.shadow_size = 60
	st.shadow_color = Color(0, 0, 0, 0.7)
	_card = UI.panel(Rect2((Vector2(1920, 1080) - CARD_SIZE) * 0.5, CARD_SIZE), st)
	_card.pivot_offset = CARD_SIZE * 0.5
	add_child(_card)
	# An inner hairline frame for a touch of ceremony.
	var inner := UI.panel(Rect2(Vector2(14, 14), CARD_SIZE - Vector2(28, 28)),
		UI.panel_style(Config.GOLD, 0.28, 0.0))
	inner.get_theme_stylebox("panel").shadow_size = 0
	_card.add_child(inner)
	visible = false
	modulate.a = 0.0


func show_award(info: Dictionary) -> void:
	var first := not visible
	visible = true
	if _box:
		_box.queue_free()
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 10)
	_box.position = Vector2(60, 40)
	_box.size = CARD_SIZE - Vector2(120, 80)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_box)

	_box.add_child(UI.eyebrow("The award for", 15, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var title := UI.label(info["title"].to_upper(), UI.Face.DISPLAY, 50, Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER, 6)
	title.material = UI.gold_material()
	_box.add_child(title)
	var orn := Ornament.new(460, true)
	orn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(orn)
	_box.add_child(_spacer(18))
	_box.add_child(UI.label("is awarded to", UI.Face.ITALIC, 32, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	var winners: Array = info["winners"]
	var names := " & ".join(winners.map(func(p): return data.name_of(p)))
	var size_px := 116
	var f := UI.font(UI.Face.SERIF_BOLD)
	while size_px > 56 and f.get_string_size(names, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > CARD_SIZE.x - 180:
		size_px -= 4
	var name_l := UI.label(names, UI.Face.SERIF_BOLD, size_px, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_l.material = UI.gold_material()
	name_l.custom_minimum_size.y = 128
	_box.add_child(name_l)

	var swatches := HBoxContainer.new()
	swatches.alignment = BoxContainer.ALIGNMENT_CENTER
	swatches.add_theme_constant_override("separation", 10)
	for p in winners:
		var s := ColorRect.new()
		s.color = data.colour_of(p)
		s.custom_minimum_size = Vector2(72, 3)
		swatches.add_child(s)
	_box.add_child(swatches)
	_box.add_child(_spacer(14))
	_box.add_child(UI.label(info.get("stat", ""), UI.Face.NUMBER, 30, Config.SAND,
		HORIZONTAL_ALIGNMENT_CENTER, 3))
	if info.get("note", "") != "":
		_box.add_child(UI.label(info["note"], UI.Face.ITALIC, 28, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	# Animate: card rises in, then the name is revealed with sparks.
	var hidden := [name_l, swatches]
	for n in hidden:
		n.modulate.a = 0.0
	var tw := create_tween()
	if first:
		_card.scale = Vector2(0.94, 0.94)
		tw.set_parallel()
		tw.tween_property(self, "modulate:a", 1.0, 0.5)
		tw.tween_property(_card, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.chain()
	else:
		_box.modulate.a = 0.0
		tw.tween_property(_box, "modulate:a", 1.0, 0.4)
	tw.tween_interval(0.7)
	tw.tween_callback(func():
		for n in hidden:
			create_tween().tween_property(n, "modulate:a", 1.0, 0.6)
		add_child(GoldBurst.new(Rect2(Vector2(560, 470), Vector2(800, 90)))))


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
