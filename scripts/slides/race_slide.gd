class_name RaceSlide
extends Slide
## Shared layout for the "live race" slides: a growing line chart on
## the left, and a "now playing" ticker, a live leaderboard and a key on
## the right. Click 1 plays every game in order; later clicks show the
## award cards. Subclasses fill in the hooks below.

const CHART_W := 1010.0
const GAP := 40.0
const TICKER_H := 168.0

var chart: RaceChart
var table: StandingsTable
var _tick_game: Label
var _tick_main: Label
var _tick_sub: Label
var _live := true


# ── Hooks for subclasses ─────────────────────────────────────────────

## [eyebrow, title, subtitle]
func header_text() -> Array:
	return ["", "", ""]


## player -> Array of values (index 0 = before game 1, length games+1)
func chart_series() -> Dictionary:
	return {}


func chart_axis_title() -> String:
	return ""


## [{key, header, width}] for the leaderboard.
func table_columns() -> Array:
	return []


## [{colour, text}] for the key under the leaderboard.
func legend_items() -> Array:
	return []


## Put the leaderboard into its "before game 1" state.
func reset_state() -> void:
	pass


## Called as the chart passes game number `index` (1-based position in
## data.games). `live` is false when skipping ahead: update numbers only.
func apply_game(_index: int, _live_mode: bool) -> void:
	pass


# ── Layout ───────────────────────────────────────────────────────────

func build() -> void:
	var h := header_text()
	var top := add_header(h[0], h[1], h[2]) + 30.0
	var bottom := H - 94.0

	chart = RaceChart.new()
	chart.position = Vector2(MARGIN, top)
	chart.size = Vector2(CHART_W, bottom - top)
	chart.players = data.players
	chart.series = chart_series()
	chart.n_games = data.games.size()
	chart.spans = data.expansion_spans()
	chart.axis_title = chart_axis_title()
	for p in data.players:
		chart.colours[p] = data.colour_of(p)
		chart.names[p] = data.name_of(p)
	var biggest := 1.0
	for p in chart.series:
		biggest = maxf(biggest, chart.series[p].max())
	chart.fit_axis(biggest)
	add(chart)

	var x := MARGIN + CHART_W + GAP
	var w := W - MARGIN - x
	_build_ticker(Rect2(x, top, w, TICKER_H))

	var legend_y := bottom - 18.0
	table = StandingsTable.new()
	table.position = Vector2(x, top + TICKER_H + 20.0)
	table.size = Vector2(w, legend_y - 22.0 - table.position.y)
	add(table)
	table.setup(data, table_columns())

	var legend := FlashLegend.new(legend_items())
	legend.position = Vector2(x + 2, legend_y)
	legend.size = Vector2(w, 18)
	add(legend)

	reset_state()
	chart.game_reached.connect(func(i): apply_game(i, _live))
	set_ticker("Before the first game", "The chronicle awaits", Config.SAND,
		"Click to play all %d games" % data.games.size())

	add_step(_play_all)
	add_award_card_steps(get_awards())


func _build_ticker(r: Rect2) -> void:
	add(UI.panel(r))
	_tick_game = UI.label("", UI.Face.NUMBER, 20, Config.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 2)
	_tick_game.position = r.position + Vector2(26, 18)
	_tick_game.size = Vector2(r.size.x - 52, 24)
	add(_tick_game)
	_tick_main = UI.label("", UI.Face.SERIF_BOLD, 42, Config.SAND)
	_tick_main.position = r.position + Vector2(26, 46)
	_tick_main.size = Vector2(r.size.x - 52, 60)
	_tick_main.clip_text = true
	_tick_main.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add(_tick_main)
	_tick_sub = UI.label("", UI.Face.ITALIC, 28, Config.SAND_DIM)
	_tick_sub.position = r.position + Vector2(26, 108)
	_tick_sub.size = Vector2(r.size.x - 52, 40)
	_tick_sub.clip_text = true
	_tick_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add(_tick_sub)


func set_ticker(game_line: String, main: String, main_colour: Color, sub: String,
		sub_colour := Config.SAND_DIM) -> void:
	_tick_game.text = game_line.to_upper()
	_tick_main.text = main
	_tick_main.add_theme_color_override("font_color", main_colour)
	_tick_sub.text = sub
	_tick_sub.add_theme_color_override("font_color", sub_colour)


## "Game 18 · Rise of Ix"
func game_line(index: int) -> String:
	var g: Dictionary = data.games[index - 1]
	return "Game %d  ·  %s" % [g["number"], data.expansion_name(g["expansion"])]


# ── Playback ─────────────────────────────────────────────────────────

func _play_all() -> void:
	var tw := tween()
	tw.tween_property(chart, "progress", float(chart.n_games),
		chart.n_games * Config.SECONDS_PER_GAME)
	play(tw, _skip_to_end)


func _skip_to_end() -> void:
	_live = false
	chart.progress = float(chart.n_games)
	chart.clear_flashes()
	_live = true
	var last := data.games.size()
	set_ticker(game_line(last), "Every game played", Config.SAND,
		"The final standings")
