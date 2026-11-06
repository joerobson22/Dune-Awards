class_name FaveAllianceSlide
extends Slide
## The screen splits into one column per alliance (Config.ALLIANCES).
## Each click reveals who called that alliance their favourite.
## Reads the "Fave Alliance" stat from data/core_stats.csv.

const STAT := "Fave Alliance"

var _cols := []


func build() -> void:
	var top := add_header("Where our loyalties lie", "Favourite alliances",
		"The alliance each of us courted most often") + 34.0
	var n: int = Config.ALLIANCES.size()
	var gap := 24.0
	var w := (W - MARGIN * 2 - gap * (n - 1)) / n
	var h := H - 94.0 - top
	var fans := _fans()
	for i in n:
		var a: Dictionary = Config.ALLIANCES[i]
		var rect := Rect2(MARGIN + i * (w + gap), top, w, h)
		_cols.append(_make_column(a, rect, fans.get(a["name"], [])))
		add_step(_reveal.bind(i))


## Alliance name -> [player tags] whose favourite it is.
func _fans() -> Dictionary:
	var out := {}
	for s in data.core_stats:
		if s["stat"] != STAT:
			continue
		for p in data.players:
			var alliance: String = s["values"].get(p, "")
			if alliance != "":
				if not out.has(alliance):
					out[alliance] = []
				out[alliance].append(p)
	return out

## Where the names land in each column; the rest is placed above it.
const NAMES_Y := 460.0


func _make_column(a: Dictionary, rect: Rect2, fans: Array) -> Dictionary:
	var st := UI.panel_style(Config.GOLD, 0.22, 0.8)
	var panel := UI.panel(rect, st)
	add(panel)
	# A faint wash of the alliance colour, strongest at the top.
	var wash := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(a["colour"], 0.22))
	g.set_color(1, Color(a["colour"], 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 0.75)
	wash.texture = gt
	wash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wash.stretch_mode = TextureRect.STRETCH_SCALE
	wash.position = Vector2(1, 1)
	wash.size = rect.size - Vector2(2, 2)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.modulate.a = 0.35
	panel.add_child(wash)

	# Content block offset so it sits centred in the tall column.
	var oy := NAMES_Y - 380.0
	var emblem := AllianceEmblem.new(a["key"], 170.0)
	emblem.tint = a["colour"]
	emblem.position = Vector2((rect.size.x - 170.0) * 0.5, 48 + oy)
	panel.add_child(emblem)
	var name_l := UI.label(a["name"].to_upper(), UI.Face.DISPLAY, 22, Config.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 4)
	name_l.position = Vector2(0, 244 + oy)
	name_l.size = Vector2(rect.size.x, 36)
	panel.add_child(name_l)
	var orn := Ornament.new(rect.size.x * 0.55, true)
	orn.position = Vector2(rect.size.x * 0.225, 292 + oy)
	panel.add_child(orn)
	var by := UI.label("the favourite of", UI.Face.ITALIC, 26, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	by.position = Vector2(0, 322 + oy)
	by.size = Vector2(rect.size.x, 36)
	panel.add_child(by)

	var placeholder := UI.label("·  ·  ·", UI.Face.DISPLAY, 26, Config.SAND_FAINT, HORIZONTAL_ALIGNMENT_CENTER)
	placeholder.position = Vector2(0, NAMES_Y)
	placeholder.size = Vector2(rect.size.x, 80)
	panel.add_child(placeholder)

	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 18)
	names.position = Vector2(20, NAMES_Y)
	names.size = Vector2(rect.size.x - 40, rect.size.y - NAMES_Y - 20)
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.modulate.a = 0.0
	panel.add_child(names)
	if fans.is_empty():
		names.add_child(UI.label("No one", UI.Face.ITALIC, 44, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	for p in fans:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		var nm := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, _fit(data.name_of(p), rect.size.x - 40), data.colour_of(p),
			HORIZONTAL_ALIGNMENT_CENTER)
		col.add_child(nm)
		var bar := ColorRect.new()
		bar.color = data.colour_of(p)
		bar.custom_minimum_size = Vector2(80, 3)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(bar)
		names.add_child(col)
	return {"panel": panel, "style": st, "wash": wash, "placeholder": placeholder, "names": names,
		"fans": fans}


## Largest size up to 60px at which a name fits the column.
func _fit(text: String, width: float) -> int:
	var f := UI.font(UI.Face.SERIF_BOLD)
	var s := 60
	while s > 30 and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > width:
		s -= 2
	return s


func _reveal(i: int) -> void:
	var c: Dictionary = _cols[i]
	var st: StyleBoxFlat = c["style"]
	var names: Control = c["names"]
	names.position.y += 16
	var tw := tween().set_parallel()
	tw.tween_property(st, "border_color", Color(Config.GOLD, 0.8), 0.6)
	tw.tween_property(c["wash"], "modulate:a", 1.0, 0.8)
	tw.tween_property(c["placeholder"], "modulate:a", 0.0, 0.3)
	tw.tween_property(names, "modulate:a", 1.0, 0.8).set_delay(0.25)
	tw.tween_property(names, "position:y", names.position.y - 16, 0.9).set_delay(0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var p: Panel = c["panel"]
	tw.tween_callback(func(): add(GoldBurst.new(Rect2(p.position + Vector2(20, NAMES_Y - 10), Vector2(p.size.x - 40, 90)), 90))).set_delay(0.3)
	play(tw, func():
		st.border_color = Color(Config.GOLD, 0.8)
		c["wash"].modulate.a = 1.0
		c["placeholder"].modulate.a = 0.0
		names.modulate.a = 1.0
		names.position.y = NAMES_Y)
