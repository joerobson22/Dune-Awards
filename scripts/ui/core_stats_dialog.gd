class_name CoreStatsDialog
extends FormDialog
## The "Change core stats" form on the stats overview: every stat in
## core_stats.csv, one row each, with a box per player. Saving rewrites
## core_stats.csv in the data folder, and the Muad'Dib and favourite
## alliance slides pick up the new numbers.

signal saved(message: String)

const STAT_W := 340.0
const COL_GAP := 22.0
const ROW_H := 54.0
const GROUP_H := 44.0
const FIELD_H := 42.0
const HEAD_Y := 166.0

## Stat name in the CSV -> name shown on screen, and stats where lower
## wins: read from the Muad'Dib slide so both say the same thing.
var labels := {}
var lower_wins: Array = []

var _fields: Array = []   # {stat index, player, control, original, numeric}


func _init(game_data: GameData, stat_labels := {}, lower: Array = []) -> void:
	super(game_data)
	card_size = Vector2(1306, 960)
	labels = stat_labels
	lower_wins = lower


func heading() -> Array:
	return ["Muad'Dib and favourite alliances", "Change core stats"]


func primary_text() -> String:
	return "Save"


func first_focus() -> Control:
	for f in _fields:
		if f["numeric"]:
			return f["control"]
	return null


func _col_x(i: int) -> float:
	var w := _col_w()
	return PAD + STAT_W + COL_GAP + i * (w + COL_GAP)


func _col_w() -> float:
	var n := maxi(1, data.players.size())
	return (inner_w() - STAT_W - COL_GAP * n) / n


func build_body() -> void:
	# Column headers: "Stat", then each player over their column.
	var sh := UI.eyebrow("Stat", 12, Config.SAND_DIM)
	sh.position = Vector2(PAD, HEAD_Y)
	sh.size = Vector2(STAT_W, 30)
	_card.add_child(sh)
	for i in data.players.size():
		var p := data.players[i]
		var nm := UI.label(data.name_of(p), UI.Face.SERIF_BOLD, 24, Config.SAND, HORIZONTAL_ALIGNMENT_CENTER)
		nm.position = Vector2(_col_x(i), HEAD_Y - 6)
		nm.size = Vector2(_col_w(), 32)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_card.add_child(nm)
		var bar := ColorRect.new()
		bar.color = data.colour_of(p)
		bar.size = Vector2(minf(_col_w() * 0.6, 120.0), 3)
		bar.position = Vector2(_col_x(i) + (_col_w() - bar.size.x) * 0.5, HEAD_Y + 28)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_card.add_child(bar)
	add_rule(HEAD_Y + 40)

	# The rows scroll under the fixed headers.
	var top := HEAD_Y + 48
	var sc := ScrollContainer.new()
	sc.position = Vector2(PAD, top)
	sc.size = Vector2(inner_w() + 30, status_y() - 12 - top)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	_card.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.custom_minimum_size = Vector2(inner_w(), 0)
	sc.add_child(list)

	var group := ""
	for si in data.core_stats.size():
		var s: Dictionary = data.core_stats[si]
		if s["group"] != group:
			group = s["group"]
			list.add_child(_group_row(group))
		list.add_child(_stat_row(si, s))


func _group_row(group: String) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(inner_w(), GROUP_H)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name: String = "Core" if group == "Core" else data.expansion_name(group)
	var l := UI.eyebrow(name, 12, Config.GOLD)
	l.position = Vector2(0, GROUP_H - 26)
	l.size = Vector2(inner_w(), 22)
	row.add_child(l)
	return row


func _stat_row(si: int, s: Dictionary) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(inner_w(), ROW_H)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stat: String = s["stat"]
	var numeric := true
	for p in s["values"]:
		if not s["values"][p].is_valid_float():
			numeric = false
	var label: String = labels.get(stat, stat.trim_prefix("Avg. "))
	var hint := ""
	if stat.begins_with("%"):
		hint = "percent"
	elif stat.begins_with("Avg."):
		hint = "average"
	if stat in lower_wins:
		hint += ("  ·  " if hint != "" else "") + "lowest wins"
	var nm := UI.label(label, UI.Face.SERIF_BOLD, 24, Config.SAND)
	var nw := UI.font(UI.Face.SERIF_BOLD).get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	nm.position = Vector2(0, 0)
	nm.size = Vector2(minf(nw + 2, STAT_W), ROW_H)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(nm)
	if hint != "" and nw + 12 < STAT_W - 40:
		var h := UI.label(hint, UI.Face.ITALIC, 18, Config.SAND_FAINT)
		h.position = Vector2(nw + 12, 2)
		h.size = Vector2(STAT_W - nw - 12, ROW_H)
		h.clip_text = true
		h.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(h)
	var fy := (ROW_H - FIELD_H) * 0.5
	for i in data.players.size():
		var p := data.players[i]
		var value: String = s["values"].get(p, "")
		var rect := Rect2(_col_x(i) - PAD, fy, _col_w(), FIELD_H)
		var c: Control
		if numeric:
			var f := number_field(rect, true, 7)
			f.text = value
			f.select_all_on_focus = true
			c = f
		elif stat == "Fave Alliance":
			c = _alliance_pick(rect, value)
		else:
			var t := LineEdit.new()
			t.position = rect.position
			t.size = rect.size
			t.alignment = HORIZONTAL_ALIGNMENT_CENTER
			t.add_theme_font_override("font", UI.font(UI.Face.SERIF))
			t.add_theme_font_size_override("font_size", 22)
			t.text = value
			t.text_changed.connect(func(_t): refresh())
			c = t
		row.add_child(c)
		_fields.append({"stat": si, "player": p, "control": c, "original": value, "numeric": numeric})
	var line := ColorRect.new()
	line.color = Color(Config.GOLD, 0.08)
	line.position = Vector2(0, ROW_H - 1)
	line.size = Vector2(inner_w(), 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	return row


## A drop-down of the alliances in config.gd (plus the current value if
## it is something else).
func _alliance_pick(rect: Rect2, value: String) -> OptionButton:
	var pick := OptionButton.new()
	var names: Array = Config.ALLIANCES.map(func(a): return a["name"])
	if value != "" and value not in names:
		names.append(value)
	for n in names:
		pick.add_item(n)
	pick.select(names.find(value))
	pick.position = rect.position
	pick.size = rect.size
	pick.clip_text = true
	pick.fit_to_longest_item = false
	pick.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.add_theme_font_size_override("font_size", 22)
	pick.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pick.item_selected.connect(func(_i): refresh())
	return pick


func _value_of(f: Dictionary) -> String:
	var c: Control = f["control"]
	if c is OptionButton:
		return c.get_item_text(c.selected) if c.selected >= 0 else ""
	var t: String = c.text.strip_edges()
	if f["numeric"] and t.ends_with("."):
		t = t.trim_suffix(".")
	return t


func refresh() -> void:
	var changed := 0
	var bad := 0
	for f in _fields:
		var v := _value_of(f)
		var ok: bool = not f["numeric"] or v.is_valid_float()
		if not ok:
			bad += 1
		if v != f["original"]:
			changed += 1
		var c: Control = f["control"]
		if c is LineEdit:
			if not ok:
				c.add_theme_stylebox_override("normal", UI.box(Color(Config.RECORD_COLOUR, 0.1), Config.RECORD_COLOUR, 12, 4))
			elif v != f["original"]:
				c.add_theme_stylebox_override("normal", UI.box(Color(Config.GOLD, 0.1), Config.GOLD, 12, 4))
			else:
				c.remove_theme_stylebox_override("normal")
	if bad > 0:
		set_status("[color=#%s]%s empty. Every stat needs a number for each player.[/color]"
			% [Config.RECORD_COLOUR.to_html(false), "1 box is" if bad == 1 else "%d boxes are" % bad], false)
	elif changed == 0:
		set_status("Change any number, then save. Changed boxes are outlined in gold.", false)
	else:
		set_status("[color=#%s]%s changed.[/color]  Saving updates Muad'Dib and the favourite alliances."
			% [Config.GOLD_BRIGHT.to_html(false), UI.plural(changed, "value")], true)


func submit() -> void:
	var stats := []
	for s in data.core_stats:
		stats.append({"group": s["group"], "stat": s["stat"], "values": s["values"].duplicate()})
	var changed := 0
	for f in _fields:
		var v := _value_of(f)
		if v != f["original"]:
			changed += 1
		stats[f["stat"]]["values"][f["player"]] = v
	var err := data.save_core_stats(stats)
	if err != "":
		show_error(err)
		return
	saved.emit("Core stats saved: %s changed." % UI.plural(changed, "value"))
	close()
