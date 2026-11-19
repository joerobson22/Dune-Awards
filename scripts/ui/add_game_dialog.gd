class_name AddGameDialog
extends Control
## The "Add new game" form on the stats overview. Pick the expansion,
## then each player's leader and VPs. Spice, solari and water are only
## asked for when players are level; Chaumurky is a toggle. The winner is
## worked out with the game's rules (GameData.decide_winner) and the
## game is added to the end of data/games.csv.

signal saved(game: int, message: String)

const CARD_W := 1306.0
const CARD_H := 742.0
const PAD := 60.0
const COL_GAP := 22.0
const ROW_H := 64.0
const FIELD_H := 46.0
const NEW_LEADER := "New leader…"
## Column widths, left to right.
const COLS := [
	{"key": "player", "text": "Player", "w": 250.0},
	{"key": "leader", "text": "Leader", "w": 270.0},
	{"key": "vp", "text": "VP", "w": 96.0},
	{"key": "spice", "text": "Spice", "w": 96.0},
	{"key": "solari", "text": "Solari", "w": 96.0},
	{"key": "water", "text": "Water", "w": 96.0},
	{"key": "chaumurky", "text": "Chaumurky", "w": 150.0},
]

var data: GameData
var expansion := ""
var _card: Panel
var _rows: Array = []   # per player: {player, leader_pick, leader_text, fields: {key: LineEdit}, chaum}
var _status: RichTextLabel
var _add: Button
var _valid := false


func _init(game_data: GameData) -> void:
	data = game_data


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
	_card = UI.panel(Rect2((size - Vector2(CARD_W, CARD_H)) * 0.5, Vector2(CARD_W, CARD_H)), st)
	add_child(_card)
	_build()
	_refresh()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	_rows[0]["leader_pick"].grab_focus()


func _build() -> void:
	var inner_w := CARD_W - PAD * 2
	var e := UI.eyebrow("Game %d" % data.next_game_number(), 14, Config.SAND_DIM)
	e.position = Vector2(PAD, 44)
	e.size = Vector2(inner_w, 22)
	_card.add_child(e)
	var t := UI.label("ADD NEW GAME", UI.Face.DISPLAY, 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 5)
	t.material = UI.gold_material()
	t.position = Vector2(PAD - 2, 68)
	t.size = Vector2(inner_w, 52)
	_card.add_child(t)
	var o := Ornament.new(420)
	o.position = Vector2(PAD, 124)
	_card.add_child(o)

	# Expansion: one chip each, the last game's box picked to start.
	var el := UI.eyebrow("Expansion", 12, Config.SAND_DIM)
	el.position = Vector2(PAD, 160)
	el.size = Vector2(300, 20)
	_card.add_child(el)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	chips.position = Vector2(PAD, 188)
	_card.add_child(chips)
	expansion = data.games[-1]["expansion"] if not data.games.is_empty() else Config.EXPANSIONS.keys()[0]
	var codes: Array = Config.EXPANSIONS.keys()
	if expansion not in codes:
		codes.append(expansion)
	var group := ButtonGroup.new()
	for code in codes:
		var b := UI.chip(StatsOverviewSlide.short_expansion(code), group, 22)
		b.custom_minimum_size = Vector2(0, 40)
		b.button_pressed = code == expansion
		b.pressed.connect(func(): expansion = code)
		chips.add_child(b)

	# The table: headers, a rule, then a row per player.
	var hy := 256.0
	for c in COLS:
		var colour: Color = Config.METHOD_COLOURS.get(c["text"], Config.SAND_DIM)
		var l := UI.eyebrow(c["text"], 12, Config.SAND_DIM)
		l.position = Vector2(_col_x(c["key"]), hy)
		l.size = Vector2(c["w"], 24)
		_card.add_child(l)
		if c["key"] in ["spice", "solari", "water", "chaumurky"]:
			var tw := l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var dot := Dot.new(colour)
			dot.position = Vector2(_col_x(c["key"]) + tw + 8, hy + 7)
			_card.add_child(dot)
	var rule := ColorRect.new()
	rule.color = Color(Config.GOLD, 0.3)
	rule.position = Vector2(PAD, hy + 30)
	rule.size = Vector2(inner_w, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(rule)
	var leaders := data.leaders()
	for i in data.players.size():
		_rows.append(_make_row(data.players[i], hy + 40 + i * ROW_H, leaders))

	_status = RichTextLabel.new()
	_status.bbcode_enabled = true
	_status.scroll_active = false
	_status.fit_content = false
	_status.position = Vector2(PAD, hy + 40 + data.players.size() * ROW_H + 14)
	_status.size = Vector2(inner_w, 64)
	_status.add_theme_font_override("normal_font", UI.font(UI.Face.ITALIC))
	_status.add_theme_font_override("bold_font", UI.font(UI.Face.SERIF_BOLD))
	_status.add_theme_font_size_override("normal_font_size", 25)
	_status.add_theme_font_size_override("bold_font_size", 25)
	_status.add_theme_color_override("default_color", Config.SAND_DIM)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_status)

	var by := CARD_H - 44.0 - 48.0
	_add = Button.new()
	_add.text = "Add game"
	_add.size = Vector2(190, 48)
	_add.position = Vector2(CARD_W - PAD - 190, by)
	_add.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_add.pressed.connect(_submit)
	_card.add_child(_add)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.size = Vector2(150, 48)
	cancel.position = Vector2(CARD_W - PAD - 190 - 14 - 150, by)
	cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel.pressed.connect(close)
	_card.add_child(cancel)
	var keys := UI.label("Tab moves between boxes  ·  Enter adds  ·  Esc cancels", UI.Face.ITALIC, 20, Config.SAND_FAINT)
	keys.position = Vector2(PAD, by)
	keys.size = Vector2(600, 48)
	_card.add_child(keys)


func _col_x(key: String) -> float:
	var x := PAD
	for c in COLS:
		if c["key"] == key:
			return x
		x += c["w"] + COL_GAP
	return x


func _col_w(key: String) -> float:
	for c in COLS:
		if c["key"] == key:
			return c["w"]
	return 0.0


func _make_row(player: String, y: float, leaders: Array) -> Dictionary:
	var fy := y + (ROW_H - FIELD_H) * 0.5
	var bar := ColorRect.new()
	bar.color = data.colour_of(player)
	bar.position = Vector2(PAD, y + ROW_H * 0.5 - 18)
	bar.size = Vector2(4, 36)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(bar)
	var nm := UI.label(data.name_of(player), UI.Face.SERIF_BOLD, 30, Config.SAND)
	nm.position = Vector2(PAD + 18, y)
	nm.size = Vector2(_col_w("player") - 18, ROW_H)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_card.add_child(nm)

	var pick := OptionButton.new()
	pick.add_item("Choose leader")
	pick.set_item_disabled(0, true)
	for l in leaders:
		pick.add_item(l)
	pick.add_separator()
	pick.add_item(NEW_LEADER)
	pick.select(0)
	pick.get_popup().max_size = Vector2i(600, 520)  # longer lists scroll
	pick.fit_to_longest_item = false
	pick.clip_text = true
	pick.add_theme_font_size_override("font_size", 24)
	pick.position = Vector2(_col_x("leader"), fy)
	pick.size = Vector2(_col_w("leader"), FIELD_H)
	pick.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_card.add_child(pick)
	var typed := LineEdit.new()
	typed.placeholder_text = "Leader's name"
	typed.add_theme_font_override("font", UI.font(UI.Face.SERIF))
	typed.add_theme_font_size_override("font_size", 24)
	typed.position = pick.position
	typed.size = pick.size
	typed.visible = false
	_card.add_child(typed)

	var row := {"player": player, "leader_pick": pick, "leader_text": typed, "fields": {}}
	pick.item_selected.connect(func(i):
		if pick.get_item_text(i) == NEW_LEADER:
			pick.visible = false
			typed.visible = true
			typed.grab_focus()
		_refresh())
	typed.text_changed.connect(func(_t): _refresh())
	# Back to the list if the typed name is left empty.
	typed.focus_exited.connect(func():
		if typed.text.strip_edges() == "":
			typed.visible = false
			pick.visible = true
			pick.select(0)
			_refresh())

	for key in ["vp", "spice", "solari", "water"]:
		var f := LineEdit.new()
		f.alignment = HORIZONTAL_ALIGNMENT_CENTER
		f.max_length = 3
		f.add_theme_font_size_override("font_size", 24)
		f.position = Vector2(_col_x(key), fy)
		f.size = Vector2(_col_w(key), FIELD_H)
		f.text_changed.connect(_on_number.bind(f))
		_card.add_child(f)
		row["fields"][key] = f

	var ch := Button.new()
	ch.toggle_mode = true
	ch.text = "Not held"
	ch.add_theme_font_size_override("font_size", 21)
	var purple: Color = Config.METHOD_COLOURS["Chaumurky"]
	ch.add_theme_stylebox_override("pressed", UI.box(Color(purple, 0.25), purple))
	ch.add_theme_stylebox_override("hover_pressed", UI.box(Color(purple, 0.32), purple.lightened(0.3)))
	ch.add_theme_color_override("font_color", Config.SAND_FAINT)
	ch.add_theme_color_override("font_pressed_color", purple.lightened(0.45))
	ch.add_theme_color_override("font_hover_pressed_color", purple.lightened(0.45))
	ch.position = Vector2(_col_x("chaumurky"), fy)
	ch.size = Vector2(_col_w("chaumurky"), FIELD_H)
	ch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ch.toggled.connect(_on_chaumurky.bind(ch))
	_card.add_child(ch)
	row["chaum"] = ch
	return row


## Keeps number boxes to digits only.
func _on_number(text: String, f: LineEdit) -> void:
	var digits := ""
	for c in text:
		if c >= "0" and c <= "9":
			digits += c
	if digits != text:
		var caret := f.caret_column
		f.text = digits
		f.caret_column = mini(caret, digits.length())
	_refresh()


## Only one player can hold Chaumurky.
func _on_chaumurky(on: bool, ch: Button) -> void:
	ch.text = "Held" if on else "Not held"
	if on:
		for r in _rows:
			if r["chaum"] != ch and r["chaum"].button_pressed:
				r["chaum"].set_pressed_no_signal(false)
				r["chaum"].text = "Not held"
	_refresh()


# ── Reading and checking the form ────────────────────────────────────

func _leader_of(r: Dictionary) -> String:
	if r["leader_text"].visible:
		var typed: String = r["leader_text"].text.strip_edges()
		# Match a known leader whatever the capitals, so stats stay together.
		for l in data.leaders():
			if l.to_lower() == typed.to_lower():
				return l
		return typed
	var pick: OptionButton = r["leader_pick"]
	return pick.get_item_text(pick.selected) if pick.selected > 0 else ""


func _num(r: Dictionary, key: String) -> int:
	var t: String = r["fields"][key].text
	return int(t) if t.is_valid_int() else -1


## The form as games.csv rows (see GameData.append_game).
func _results() -> Array:
	var out := []
	for r in _rows:
		out.append({"player": r["player"], "leader": _leader_of(r), "vp": _num(r, "vp"),
			"spice": _num(r, "spice"), "solari": _num(r, "solari"), "water": _num(r, "water"),
			"chaumurky": r["chaum"].button_pressed})
	return out


func _names(indices: Array) -> String:
	var names: Array = indices.map(func(i): return "[b]%s[/b]" % data.name_of(_rows[i]["player"]))
	if names.size() <= 1:
		return "".join(names)
	return ", ".join(names.slice(0, -1)) + " and " + names[-1]


func _refresh() -> void:
	var res := _results()
	var needed := {}   # "index:key" -> true (required) / false (optional)
	var message := ""
	_valid = false

	var no_leader := range(res.size()).filter(func(i): return res[i]["leader"] == "")
	var no_vp := range(res.size()).filter(func(i): return res[i]["vp"] < 0)
	var seen := {}
	var twice := ""
	for r in res:
		if r["leader"] != "":
			if seen.has(r["leader"]):
				twice = r["leader"]
			seen[r["leader"]] = true

	if not no_leader.is_empty() or not no_vp.is_empty():
		message = "Choose a leader and enter the VPs for every player."
	elif twice != "":
		message = "[color=#%s]%s is picked twice. Each player needs their own leader.[/color]" \
			% [Config.RECORD_COLOUR.to_html(false), twice]
	else:
		var asks := data.tiebreak_requests(res)
		for a in asks:
			needed["%d:%s" % [a["index"], a["key"]]] = a["required"]
		var missing := asks.filter(func(a): return a["required"] and res[a["index"]][a["key"]] < 0)
		if not missing.is_empty():
			var key: String = missing[0]["key"]
			var who := missing.filter(func(a): return a["key"] == key).map(func(a): return a["index"])
			var level := "level on %d VP" % res[who[0]]["vp"]
			if key != "spice":
				level = "still level on %s" % Config.TIEBREAK_ORDER[Config.TIEBREAK_ORDER.find(key) - 1]
			message = "%s are %s. Enter their %s to settle it." % [_names(who), level, key]
		else:
			_valid = true
			var d := data.decide_winner(res)
			var how := _method_text(d["method"])
			var colour: Color = Config.METHOD_COLOURS.get(d["method"], Config.GOLD_BRIGHT)
			message = "[color=#%s]%s wins on %s.[/color]" % [colour.to_html(false),
				data.name_of(res[d["index"]]["player"]), how]
			var optional := asks.filter(func(a): return not a["required"] and res[a["index"]][a["key"]] < 0)
			if not optional.is_empty():
				var key: String = optional[0]["key"]
				var who := optional.filter(func(a): return a["key"] == key).map(func(a): return a["index"])
				message += "  %s are level for a lower place: add their %s to split them, if you have it." \
					% [_names(who), key]
	_status.text = message
	_add.disabled = not _valid
	_style_fields(needed)


## Gold border on a tie-break box that decides the winner; a softer one
## where it only splits a lower place. Other tie-break boxes stay dim.
func _style_fields(needed: Dictionary) -> void:
	for i in _rows.size():
		for key in ["spice", "solari", "water"]:
			var f: LineEdit = _rows[i]["fields"][key]
			var k := "%d:%s" % [i, key]
			if needed.has(k):
				var border: Color = Config.GOLD_BRIGHT if needed[k] else Color(Config.GOLD, 0.6)
				f.add_theme_stylebox_override("normal", UI.box(Color(Config.GOLD, 0.1 if needed[k] else 0.04), border, 12, 4))
				f.placeholder_text = "?" if needed[k] else ""
			else:
				f.remove_theme_stylebox_override("normal")
				f.placeholder_text = "–"
		_rows[i]["fields"]["vp"].placeholder_text = ""


# ── Saving ───────────────────────────────────────────────────────────

func _submit() -> void:
	_refresh()
	if not _valid:
		return
	var res := _results()
	var n := data.next_game_number()
	var err := data.append_game(expansion, res)
	if err != "":
		_status.text = "[color=#%s]%s[/color]" % [Config.RECORD_COLOUR.to_html(false), err]
		return
	var d := data.decide_winner(res)
	saved.emit(n, "Game %d added: %s won on %s." % [n, data.name_of(res[d["index"]]["player"]),
		_method_text(d["method"])])
	close()


## "VP", "Chaumurky", or the resource in lower case ("spice").
func _method_text(method: String) -> String:
	return method if method in ["VP", "Chaumurky"] else method.to_lower()


func close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.finished.connect(queue_free)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		# Close an open leader list first, then the form.
		for r in _rows:
			if r["leader_pick"].get_popup().visible:
				return
		get_viewport().set_input_as_handled()
		close()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		for r in _rows:
			if r["leader_pick"].get_popup().visible:
				return
		get_viewport().set_input_as_handled()
		_submit()


## A small coloured dot beside a column header.
class Dot extends Control:
	var colour: Color

	func _init(c: Color) -> void:
		colour = c
		size = Vector2(10, 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(Vector2(5, 5), 5.0, colour, true, -1.0, true)
