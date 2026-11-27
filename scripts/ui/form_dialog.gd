class_name FormDialog
extends Control
## The shared look and behaviour of the pop-up forms on the stats
## overview ("Add new game", "Change core stats"): a dimmed backdrop, a
## gold card with a heading, a status line, and Cancel beside the main
## button. Esc cancels and Enter presses the main button.
##
## A form extends this, sets `card_size` in _init(), and fills in the
## hooks: heading(), primary_text(), build_body(), refresh(), submit().

const PAD := 60.0
const BUTTON_H := 48.0
const STATUS_H := 64.0

var data: GameData
var card_size := Vector2(1306, 742)

var _card: Panel
var _status: RichTextLabel
var _primary: Button
var _valid := false
var _footer_buttons: Array = []


func _init(game_data: GameData) -> void:
	data = game_data


# ── Hooks ────────────────────────────────────────────────────────────

## [eyebrow, title]
func heading() -> Array:
	return ["", ""]


## The main button's label, e.g. "Add game".
func primary_text() -> String:
	return "Save"


## Add the form's own fields to the card, between `body_top()` and `status_y()`.
func build_body() -> void:
	pass


## Check the form; call set_status() with what to show and whether it can be saved.
func refresh() -> void:
	set_status("", true)


## Save. Call close() when done, or show_error() if it failed.
func submit() -> void:
	close()


## The field to put the cursor in when the form opens.
func first_focus() -> Control:
	return null


# ── Layout helpers ───────────────────────────────────────────────────

func inner_w() -> float:
	return card_size.x - PAD * 2


## Just below the heading.
func body_top() -> float:
	return 160.0


## The status line sits here, just above the buttons.
func status_y() -> float:
	return card_size.y - 44.0 - BUTTON_H - 14.0 - STATUS_H


func set_status(bbcode: String, valid: bool) -> void:
	_status.text = bbcode
	_valid = valid
	_primary.disabled = not valid


func show_error(message: String) -> void:
	_status.text = "[color=#%s]%s[/color]" % [Config.RECORD_COLOUR.to_html(false), message]


## A gold rule under a row of column headers.
func add_rule(y: float) -> void:
	var rule := ColorRect.new()
	rule.color = Color(Config.GOLD, 0.3)
	rule.position = Vector2(PAD, y)
	rule.size = Vector2(inner_w(), 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(rule)


## A number box. Typing is limited to digits (and one point if `decimal`).
func number_field(rect: Rect2, decimal := false, max_length := 3) -> LineEdit:
	var f := LineEdit.new()
	f.alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.max_length = max_length
	f.add_theme_font_size_override("font_size", 24)
	f.position = rect.position
	f.size = rect.size
	f.text_changed.connect(_on_number.bind(f, decimal))
	return f


func _on_number(text: String, f: LineEdit, decimal: bool) -> void:
	var clean := ""
	for c in text:
		if (c >= "0" and c <= "9") or (decimal and c == "." and "." not in clean):
			clean += c
	if clean != text:
		var caret := f.caret_column
		f.text = clean
		f.caret_column = mini(caret, clean.length())
	refresh()


# ── Building ─────────────────────────────────────────────────────────

func _ready() -> void:
	size = Vector2(1920, 1080)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.74)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_STOP  # the slide below is paused
	add_child(dim)
	var st := UI.panel_style(Config.GOLD, 0.8, 0.98)
	st.set_border_width_all(2)
	st.shadow_size = 60
	st.shadow_color = Color(0, 0, 0, 0.7)
	_card = UI.panel(Rect2((size - card_size) * 0.5, card_size), st)
	add_child(_card)
	_build_heading()
	_build_footer()
	build_body()
	# Buttons last, so Tab reaches them after the fields.
	for b in _footer_buttons:
		_card.move_child(b, -1)
	refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	var f := first_focus()
	if f:
		f.grab_focus()


func _build_heading() -> void:
	var h := heading()
	var e := UI.eyebrow(h[0], 14, Config.SAND_DIM)
	e.position = Vector2(PAD, 44)
	e.size = Vector2(inner_w(), 22)
	_card.add_child(e)
	var t := UI.label(h[1].to_upper(), UI.Face.DISPLAY, 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 5)
	t.material = UI.gold_material()
	t.position = Vector2(PAD - 2, 68)
	t.size = Vector2(inner_w(), 52)
	_card.add_child(t)
	var o := Ornament.new(420)
	o.position = Vector2(PAD, 124)
	_card.add_child(o)


func _build_footer() -> void:
	_status = RichTextLabel.new()
	_status.bbcode_enabled = true
	_status.scroll_active = false
	_status.fit_content = false
	_status.position = Vector2(PAD, status_y())
	_status.size = Vector2(inner_w(), STATUS_H)
	_status.add_theme_font_override("normal_font", UI.font(UI.Face.ITALIC))
	_status.add_theme_font_override("bold_font", UI.font(UI.Face.SERIF_BOLD))
	_status.add_theme_font_size_override("normal_font_size", 25)
	_status.add_theme_font_size_override("bold_font_size", 25)
	_status.add_theme_color_override("default_color", Config.SAND_DIM)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_status)

	var by := card_size.y - 44.0 - BUTTON_H
	_primary = Button.new()
	_primary.text = primary_text()
	_primary.size = Vector2(190, BUTTON_H)
	_primary.position = Vector2(card_size.x - PAD - 190, by)
	_primary.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_primary.pressed.connect(_try_submit)
	_card.add_child(_primary)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.size = Vector2(150, BUTTON_H)
	cancel.position = Vector2(card_size.x - PAD - 190 - 14 - 150, by)
	cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel.pressed.connect(close)
	_card.add_child(cancel)
	_footer_buttons = [cancel, _primary]
	var verb := primary_text().split(" ")[0].to_lower() + "s"   # "Add game" -> "adds"
	var keys := UI.label("Tab moves between boxes  ·  Enter %s  ·  Esc cancels" % verb,
		UI.Face.ITALIC, 20, Config.SAND_FAINT)
	keys.position = Vector2(PAD, by)
	keys.size = Vector2(600, BUTTON_H)
	_card.add_child(keys)


# ── Behaviour ────────────────────────────────────────────────────────

func _try_submit() -> void:
	refresh()
	if _valid:
		submit()


func close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.finished.connect(queue_free)


## True while a drop-down list in the form is open: Esc and Enter are
## then for the list, not the form.
func _list_open() -> bool:
	var stack: Array = [_card]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is OptionButton and n.get_popup().visible:
			return true
		stack.append_array(n.get_children())
	return false


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE and not _list_open():
		get_viewport().set_input_as_handled()
		close()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER] and not _list_open():
		get_viewport().set_input_as_handled()
		_try_submit()
