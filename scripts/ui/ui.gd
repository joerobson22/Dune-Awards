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
