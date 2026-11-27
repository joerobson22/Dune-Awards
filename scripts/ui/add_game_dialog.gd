class_name AddGameDialog
extends FormDialog
## The "Add new game" form on the stats overview. Pick the expansion,
## then each player's leader and VPs. Spice, solari and water are only
## asked for when players are level; Chaumurky is a toggle. The winner is
## worked out with the game's rules (GameData.decide_winner) and the
## game is added to the end of games.csv in the data folder.

signal saved(game: int, message: String)

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

var expansion := ""
var _rows: Array = []   # per player: {player, leader_pick, leader_text, fields: {key: LineEdit}, chaum}


func _init(game_data: GameData) -> void:
	super(game_data)
	card_size = Vector2(1306, 742)


func heading() -> Array:
	return ["Game %d" % data.next_game_number(), "Add new game"]


func primary_text() -> String:
	return "Add game"


func first_focus() -> Control:
	return _rows[0]["leader_pick"]


func build_body() -> void:
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
	add_rule(hy + 30)
	var leaders := data.leaders()
	for i in data.players.size():
		_rows.append(_make_row(data.players[i], hy + 40 + i * ROW_H, leaders))



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
		refresh())
	typed.text_changed.connect(func(_t): refresh())
	# Back to the list if the typed name is left empty.
	typed.focus_exited.connect(func():
		if typed.text.strip_edges() == "":
			typed.visible = false
			pick.visible = true
			pick.select(0)
			refresh())

	for key in ["vp", "spice", "solari", "water"]:
		var f := number_field(Rect2(_col_x(key), fy, _col_w(key), FIELD_H))
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


## Only one player can hold Chaumurky.
func _on_chaumurky(on: bool, ch: Button) -> void:
	ch.text = "Held" if on else "Not held"
	if on:
		for r in _rows:
			if r["chaum"] != ch and r["chaum"].button_pressed:
				r["chaum"].set_pressed_no_signal(false)
				r["chaum"].text = "Not held"
	refresh()


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


func refresh() -> void:
	var res := _results()
	var needed := {}   # "index:key" -> true (required) / false (optional)
	var message := ""
	var valid := false

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
			valid = true
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
	set_status(message, valid)
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

func submit() -> void:
	var res := _results()
	var n := data.next_game_number()
	var err := data.append_game(expansion, res)
	if err != "":
		show_error(err)
		return
	var d := data.decide_winner(res)
	saved.emit(n, "Game %d added: %s won on %s." % [n, data.name_of(res[d["index"]]["player"]),
		_method_text(d["method"])])
	close()


## "VP", "Chaumurky", or the resource in lower case ("spice").
func _method_text(method: String) -> String:
	return method if method in ["VP", "Chaumurky"] else method.to_lower()


## A small coloured dot beside a column header.
class Dot extends Control:
	var colour: Color

	func _init(c: Color) -> void:
		colour = c
		size = Vector2(10, 10)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(Vector2(5, 5), 5.0, colour, true, -1.0, true)
