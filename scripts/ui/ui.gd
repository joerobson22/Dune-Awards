class_name UI
extends RefCounted
## Shared building blocks: fonts, labels, panels and the gold material.
## Slides use these so every screen has the same typography.

enum Face { DISPLAY, SERIF, SERIF_BOLD, ITALIC, NUMBER }

static var _fonts := {}
static var _gold_shader: Shader


## Display = wide capitals (titles, labels). Serif = names and prose.
## Number = Roman capitals for scores. `tracking` adds letter spacing in pixels.
static func font(face: Face, tracking := 0) -> Font:
	var key := "%d_%d" % [face, tracking]
	if _fonts.has(key):
		return _fonts[key]
	var fv := FontVariation.new()
	var weight := 0
	match face:
		Face.DISPLAY:
			fv.base_font = load(Config.FONT_DISPLAY)
		Face.SERIF:
			fv.base_font = load(Config.FONT_SERIF)
			weight = 500
		Face.SERIF_BOLD:
			fv.base_font = load(Config.FONT_SERIF)
			weight = 650
		Face.ITALIC:
			fv.base_font = load(Config.FONT_SERIF_ITALIC)
			weight = 500
		Face.NUMBER:
			fv.base_font = load(Config.FONT_NUMBERS)
			weight = 600
	if weight > 0:
		var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
		fv.variation_opentype = {tag: weight}
	fv.spacing_glyph = tracking
	_fonts[key] = fv
	return fv


static func label(text: String, face: Face, size: int, colour := Config.SAND,
		align := HORIZONTAL_ALIGNMENT_LEFT, tracking := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font(face, tracking))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Small spaced capitals used above titles and as column headers.
static func eyebrow(text: String, size := 15, colour := Config.GOLD,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return label(text.to_upper(), Face.DISPLAY, size, colour, align, maxi(2, size / 4))


## The dark panel with a hairline gold border used behind charts and tables.
static func panel_style(border := Config.GOLD, border_alpha := 0.35, fill_alpha := 0.82) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(Config.INK, fill_alpha)
	s.border_color = Color(border, border_alpha)
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 18
	return s


static func panel(rect: Rect2, style: StyleBox = null) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", style if style else panel_style())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## A burnished-gold material with a slow sheen. Apply to any Label.
static func gold_material() -> ShaderMaterial:
	if _gold_shader == null:
		_gold_shader = Shader.new()
		_gold_shader.code = """
shader_type canvas_item;
uniform vec4 deep : source_color = vec4(0.62, 0.45, 0.17, 1.0);
uniform vec4 mid : source_color = vec4(0.84, 0.68, 0.36, 1.0);
uniform vec4 light : source_color = vec4(1.0, 0.93, 0.72, 1.0);
uniform float speed = 0.16;
varying vec2 world;
void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	float band = sin(world.y * 0.045) * 0.5 + 0.5;
	vec3 base = mix(mid.rgb, deep.rgb, band * 0.55);
	float sweep = fract(TIME * speed) * 3.2 - 0.6;
	float x = world.x / 1920.0 - world.y / 1080.0 * 0.25;
	float shine = smoothstep(0.09, 0.0, abs(x - sweep));
	COLOR = vec4(mix(base, light.rgb, shine * 0.85), COLOR.a);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _gold_shader
	return m


## A soft round dot, used for sparks and sand grains.
static func soft_dot(size := 24) -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


static func roman(n: int) -> String:
	var vals := [10, 9, 5, 4, 1]
	var syms := ["X", "IX", "V", "IV", "I"]
	var out := ""
	for i in vals.size():
		while n >= vals[i]:
			out += syms[i]
			n -= vals[i]
	return out


static func plural(n: int, word: String) -> String:
	return "%d %s%s" % [n, word, "" if n == 1 else "s"]


# ── Interactive controls (stats overview, add-game form) ─────────────

static var _form_theme: Theme


static func box(fill: Color, border: Color, pad_x := 14.0, pad_y := 6.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	return s


## Buttons, text boxes, drop-downs and scroll bars in the ceremony's
## colours. Set it as the `theme` of a container; children inherit it.
static func form_theme() -> Theme:
	if _form_theme:
		return _form_theme
	var t := Theme.new()
	t.default_font = font(Face.SERIF)
	t.default_font_size = 24
	var ink := Color(Config.INK, 0.95)
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, box(ink, Color(Config.GOLD, 0.4)))
		t.set_stylebox("hover", type, box(Color(Config.GOLD, 0.1), Color(Config.GOLD, 0.85)))
		t.set_stylebox("pressed", type, box(Color(Config.GOLD, 0.22), Config.GOLD))
		t.set_stylebox("hover_pressed", type, box(Color(Config.GOLD, 0.26), Config.GOLD_BRIGHT))
		t.set_stylebox("disabled", type, box(Color(Config.INK, 0.6), Color(Config.SAND_FAINT, 0.4)))
		var focus := box(Color(0, 0, 0, 0), Config.GOLD_BRIGHT)
		focus.draw_center = false
		t.set_stylebox("focus", type, focus)
		t.set_color("font_color", type, Config.SAND)
		t.set_color("font_hover_color", type, Config.GOLD_BRIGHT)
		t.set_color("font_pressed_color", type, Config.GOLD_BRIGHT)
		t.set_color("font_hover_pressed_color", type, Config.GOLD_BRIGHT)
		t.set_color("font_focus_color", type, Config.SAND)
		t.set_color("font_disabled_color", type, Config.SAND_FAINT)
	t.set_color("icon_normal_color", "OptionButton", Config.SAND_DIM)
	t.set_color("icon_hover_color", "OptionButton", Config.GOLD_BRIGHT)
	t.set_constant("arrow_margin", "OptionButton", 12)

	t.set_stylebox("normal", "LineEdit", box(Color(0, 0, 0, 0.35), Color(Config.SAND_FAINT, 0.7), 12, 4))
	t.set_stylebox("focus", "LineEdit", box(Color(0, 0, 0, 0), Config.GOLD_BRIGHT, 12, 4))
	t.set_stylebox("read_only", "LineEdit", box(Color(0, 0, 0, 0.2), Color(Config.SAND_FAINT, 0.3), 12, 4))
	t.set_color("font_color", "LineEdit", Config.SAND)
	t.set_color("font_placeholder_color", "LineEdit", Color(Config.SAND_FAINT, 0.9))
	t.set_color("caret_color", "LineEdit", Config.GOLD_BRIGHT)
	t.set_color("selection_color", "LineEdit", Color(Config.GOLD, 0.35))
	t.set_font("font", "LineEdit", font(Face.NUMBER))

	var menu := box(Color(Config.INK, 0.98), Color(Config.GOLD, 0.6), 6, 6)
	menu.shadow_color = Color(0, 0, 0, 0.6)
	menu.shadow_size = 16
	t.set_stylebox("panel", "PopupMenu", menu)
	t.set_stylebox("hover", "PopupMenu", box(Color(Config.GOLD, 0.18), Color(0, 0, 0, 0), 8, 2))
	var sep := StyleBoxLine.new()
	sep.color = Color(Config.GOLD, 0.25)
	t.set_stylebox("separator", "PopupMenu", sep)
	t.set_color("font_color", "PopupMenu", Config.SAND)
	t.set_color("font_hover_color", "PopupMenu", Config.GOLD_BRIGHT)
	t.set_color("font_disabled_color", "PopupMenu", Config.SAND_FAINT)
	t.set_color("font_separator_color", "PopupMenu", Config.SAND_FAINT)
	t.set_font("font", "PopupMenu", font(Face.SERIF))
	t.set_font_size("font_size", "PopupMenu", 22)
	t.set_constant("v_separation", "PopupMenu", 6)
	t.set_constant("item_start_padding", "PopupMenu", 12)
	t.set_constant("item_end_padding", "PopupMenu", 12)
	# The ticked item gets a small gold diamond; the others nothing.
	t.set_icon("radio_checked", "PopupMenu", _diamond_icon(12, Config.GOLD_BRIGHT))
	t.set_icon("radio_unchecked", "PopupMenu", _diamond_icon(12, Color(0, 0, 0, 0)))

	for bar in ["VScrollBar", "HScrollBar"]:
		var track := StyleBoxFlat.new()
		track.bg_color = Color(Config.GOLD, 0.06)
		track.set_corner_radius_all(3)
		track.content_margin_left = 3
		track.content_margin_right = 3
		var grab := StyleBoxFlat.new()
		grab.bg_color = Color(Config.GOLD, 0.4)
		grab.set_corner_radius_all(3)
		var grab_hi := grab.duplicate()
		grab_hi.bg_color = Color(Config.GOLD, 0.7)
		t.set_stylebox("scroll", bar, track)
		t.set_stylebox("scroll_focus", bar, track)
		t.set_stylebox("grabber", bar, grab)
		t.set_stylebox("grabber_highlight", bar, grab_hi)
		t.set_stylebox("grabber_pressed", bar, grab_hi)
	_form_theme = t
	return t


static func _diamond_icon(px: int, colour: Color) -> Texture2D:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := (px - 1) * 0.5
	for y in px:
		for x in px:
			var d := absf(x - c) + absf(y - c)
			var a := clampf(c * 0.7 - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(colour, colour.a * a))
	return ImageTexture.create_from_image(img)


## A small toggle in a row of choices (e.g. a filter). Put several in one
## ButtonGroup so one stays on.
static func chip(text: String, group: ButtonGroup, size := 19) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", box(Color(0, 0, 0, 0), Color(Config.GOLD, 0.25), 9, 2))
	b.add_theme_stylebox_override("hover", box(Color(Config.GOLD, 0.08), Color(Config.GOLD, 0.6), 9, 2))
	b.add_theme_stylebox_override("pressed", box(Color(Config.GOLD, 0.24), Config.GOLD, 9, 2))
	b.add_theme_stylebox_override("hover_pressed", box(Color(Config.GOLD, 0.28), Config.GOLD_BRIGHT, 9, 2))
	b.add_theme_color_override("font_color", Config.SAND_DIM)
	b.add_theme_color_override("font_pressed_color", Config.GOLD_BRIGHT)
	b.add_theme_color_override("font_hover_pressed_color", Config.GOLD_BRIGHT)
	return b


## Ordinal for a place: 1 -> "1st".
static func ordinal(n: int) -> String:
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][n % 10]
	return "%d%s" % [n, suffix]
