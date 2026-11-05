extends Control
## Runs the show: loads the data, builds the slides listed in
## scripts/awards.gd, and moves between them.
##
## Controls
##   Click, Space, →, Enter, Page Down   next reveal / next slide
##   Right-click, ←, Backspace, Page Up  previous slide
##   R      replay the current slide        Home   back to the start
##   F11/F  toggle full screen              Esc    leave full screen, then quit

var data := GameData.new()
var slides: Array[Slide] = []
var index := -1

var _host: Control
var _counter: Label
var _busy := false


func _ready() -> void:
	add_child(DuneBackground.new())
	_host = Control.new()
	_host.size = Vector2(1920, 1080)
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_host)
	_build_footer()
	if Config.START_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	var err := data.load_all()
	if err != "":
		_show_error(err)
		return
	slides = Awards.running_order(data)
	for s in slides:
		s.data = data
		s.ceremony = slides
	go_to(0)


func _build_footer() -> void:
	var brand := UI.eyebrow("The Dune Awards", 11, Config.SAND_FAINT)
	brand.position = Vector2(Slide.MARGIN, 1026)
	brand.size = Vector2(400, 24)
	add_child(brand)
	_counter = UI.label("", UI.Face.NUMBER, 16, Config.SAND_FAINT, HORIZONTAL_ALIGNMENT_RIGHT, 2)
	_counter.position = Vector2(1920 - Slide.MARGIN - 400, 1026)
	_counter.size = Vector2(400, 24)
	add_child(_counter)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			next()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			previous()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_RIGHT, KEY_ENTER, KEY_KP_ENTER, KEY_PAGEDOWN, KEY_DOWN:
				next()
			KEY_LEFT, KEY_BACKSPACE, KEY_PAGEUP, KEY_UP:
				previous()
			KEY_R:
				go_to(index)
			KEY_HOME:
				go_to(0)
			KEY_F11, KEY_F:
				_toggle_fullscreen()
			KEY_ESCAPE:
				if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				else:
					get_tree().quit()


func next() -> void:
	if _busy or slides.is_empty():
		return
	if not slides[index].advance() and index < slides.size() - 1:
		go_to(index + 1)


func previous() -> void:
	if _busy or index <= 0:
		return
	go_to(index - 1)


func go_to(i: int) -> void:
	if slides.is_empty():
		return
	_busy = true
	var old: Slide = slides[index] if index >= 0 and index < slides.size() else null
	index = clampi(i, 0, slides.size() - 1)
	var fade := Config.SLIDE_FADE * 0.5
	if old and old.get_parent():
		var tw := create_tween()
		tw.tween_property(old, "modulate:a", 0.0, fade)
		await tw.finished
		_host.remove_child(old)
	var s := slides[index]
	s.modulate.a = 0.0
	_host.add_child(s)
	s.enter()
	_counter.text = "%d / %d" % [index + 1, slides.size()]
	var tw_in := create_tween()
	tw_in.tween_property(s, "modulate:a", 1.0, fade)
	await tw_in.finished
	_busy = false


func _toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _show_error(message: String) -> void:
	var l := UI.label("The ceremony could not start.\n\n" + message, UI.Face.SERIF, 36,
		Config.SAND, HORIZONTAL_ALIGNMENT_CENTER)
	l.size = Vector2(1920, 1080)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	_host.add_child(l)


func _exit_tree() -> void:
	# Slides not currently on screen are held here, not in the tree.
	for s in slides:
		if is_instance_valid(s) and not s.is_inside_tree():
			s.free()
