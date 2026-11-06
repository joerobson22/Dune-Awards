extends SceneTree
## Renders the project icon and boot splash from the same art as the
## title slide, so they always match the show.
##
##   godot --path . -s res://tools/render_branding.gd
##
## Writes res://icon.png (512×512) and res://boot_splash.png (1920×1080).
## Needs a normal (windowed) run, not --headless, because it renders.

func _initialize() -> void:
	_render.call_deferred()


func _render() -> void:
	await _save(_splash(), Vector2i(1920, 1080), "res://boot_splash.png", false)
	await _save(_icon(), Vector2i(512, 512), "res://icon.png", true)
	quit()


func _save(content: Control, px: Vector2i, path: String, transparent: bool) -> void:
	var vp := SubViewport.new()
	vp.size = px
	vp.transparent_bg = transparent
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.add_child(content)
	root.add_child(vp)
	# Let fonts load and the gold sheen settle in a fixed position.
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("wrote ", path)
	vp.queue_free()


## The title slide without the names: sky, moons, dunes, gold title.
func _splash() -> Control:
	var c := Control.new()
	c.size = Vector2(1920, 1080)
	c.add_child(DuneBackground.new())
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.size = Vector2(1920, 1000)
	c.add_child(box)
	box.add_child(UI.eyebrow("A ceremony of the Imperium", 18, Config.SAND_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UI.label("THE", UI.Face.DISPLAY, 30, Config.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 14))
	box.add_child(_gold(UI.label("DUNE AWARDS", UI.Face.DISPLAY, 104, Config.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 14)))
	var orn := Ornament.new(620, true)
	orn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(orn)
	return c


## A square tile: the same night sky and dunes, with DUNE over AWARDS.
func _icon() -> Control:
	var c := IconArt.new()
	c.size = Vector2(512, 512)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.position = Vector2(0, 56)
	box.size = Vector2(512, 280)
	c.add_child(box)
	box.add_child(_gold(UI.label("DUNE", UI.Face.DISPLAY, 96, Config.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 4)))
	var orn := Ornament.new(300, true)
	orn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(orn)
	box.add_child(UI.label("AWARDS", UI.Face.DISPLAY, 40, Config.SAND, HORIZONTAL_ALIGNMENT_CENTER, 12))
	return c


## The gold gradient without the moving sheen, so the image is stable.
func _gold(l: Label) -> Label:
	var m := UI.gold_material()
	m.set_shader_parameter("speed", 0.0)
	l.material = m
	return l


class IconArt extends Panel:
	## A rounded tile. Everything inside is clipped to its corners.
	const R := 96

	func _init() -> void:
		var tile := StyleBoxFlat.new()
		tile.bg_color = Color("0b0705")
		tile.set_corner_radius_all(R)
		tile.anti_aliasing = true
		add_theme_stylebox_override("panel", tile)
		clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		var scenery := Scenery.new()
		scenery.size = Vector2(512, 512)
		add_child(scenery)

	func _ready() -> void:
		# The gold frame goes last, over the scenery and the title.
		var frame := Panel.new()
		var st := StyleBoxFlat.new()
		st.draw_center = false
		st.set_corner_radius_all(R)
		st.border_color = Color(Config.GOLD, 0.6)
		st.set_border_width_all(6)
		st.anti_aliasing = true
		frame.add_theme_stylebox_override("panel", st)
		frame.size = size
		add_child(frame)


class Scenery extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		for i in 30:
			draw_rect(Rect2(0, h * 0.45 + i * 6.0, w, 6), Color(0.55, 0.33, 0.14, sin(PI * i / 30.0) * 0.10))
		# Two moons, tucked above the title.
		draw_circle(Vector2(w * 0.79, h * 0.11), 17.0, Color(Config.SAND, 0.16), true, -1.0, true)
		draw_circle(Vector2(w * 0.875, h * 0.165), 7.0, Color(Config.SAND, 0.12), true, -1.0, true)
		_dune(h * 0.74, 16.0, 0.012, Color("22160b"), 0.35)
		_dune(h * 0.84, 12.0, 0.017, Color("2c1d0f"), 0.5)

	func _dune(base: float, amp: float, freq: float, colour: Color, rim: float) -> void:
		var crest := PackedVector2Array()
		var x := 0.0
		while x <= size.x:
			crest.append(Vector2(x, base - amp * (sin(x * freq) * 0.7 + sin(x * freq * 2.3 + 1.3) * 0.3)))
			x += 8.0
		var pts := crest.duplicate()
		pts.append(Vector2(size.x, size.y))
		pts.append(Vector2(0, size.y))
		draw_colored_polygon(pts, colour)
		draw_polyline(crest, Color(Config.GOLD, rim), 2.0, true)
