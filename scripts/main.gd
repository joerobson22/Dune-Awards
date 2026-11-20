extends Control
## Runs the show: loads the data, builds the slides listed in
## scripts/awards.gd, and moves between them.
##
## Controls
##   Click, Space, →, Enter, Page Down   next reveal / next slide
##   Right-click, ←, Backspace, Page Up  previous slide
##   R      replay the current slide        Home   back to the start
##   S      stats overview, and back again  End    stats overview
##   F11/F  toggle full screen              Esc    leave full screen, then quit

var data := GameData.new()
var slides: Array[Slide] = []
var index := -1

var _host: Control
var _counter: Label
var _busy := false
## Where S jumped to the stats from, so a second S goes back there.
var _before_stats := -1


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
	_wire_slides()
	go_to(0)


func _wire_slides() -> void:
	for s in slides:
		s.data = data
		s.ceremony = slides
		if not s.data_changed.is_connected(_on_data_changed):
			s.data_changed.connect(_on_data_changed.bind(s))
		if not s.jump_to_stats.is_connected(_go_to_stats):
			s.jump_to_stats.connect(_go_to_stats)


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
	if not slides.is_empty() and index >= 0 and slides[index].captures_input(event):
		return
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
			KEY_S:
				_toggle_stats()
			KEY_END:
				_go_to_stats()
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


func _stats_index() -> int:
	for i in slides.size():
		if slides[i] is StatsOverviewSlide:
			return i
	return slides.size() - 1


func _go_to_stats() -> void:
	var i := _stats_index()
	if _busy or i == index:
		return
	_before_stats = index
	go_to(i)


## S jumps to the stats overview; a second S returns to where you were.
func _toggle_stats() -> void:
	if _busy:
		return
	if index == _stats_index() and _before_stats >= 0:
		var back := _before_stats
		_before_stats = -1
		go_to(back)
	else:
		_go_to_stats()


## A slide changed the data files: reload them and rebuild every slide,
## so all awards and charts include the change. The slide that asked
## stays on screen and is rebuilt in place.
func _on_data_changed(source: Slide) -> void:
	var fresh := GameData.new()
	var err := fresh.load_all()
	if err != "":
		push_error(err)
		return
	data = fresh
	var order := Awards.running_order(data)
	var keep := -1
	for i in order.size():
		if order[i].get_script() == source.get_script():
			order[i].free()
			order[i] = source
			keep = i
			break
	for s in slides:
		if s != source and is_instance_valid(s) and not s.is_inside_tree():
			s.free()
	slides = order
	_wire_slides()
	if keep < 0:
		go_to(0)
		return
	index = keep
	source.enter()
	_counter.text = "%d / %d" % [index + 1, slides.size()]


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
