class_name Slide
extends Control
## Base class for every slide in the ceremony.
##
## How a slide works:
##   • build()        — make the slide's nodes. Called each time it is shown.
##   • add_step(fn)   — queue something to happen on the next click.
##   • get_awards()   — the awards this slide hands out, for the finale.
##
## A click runs the next queued step. When none are left, the show moves
## to the next slide. If an animation is running (see play()), a click
## finishes it instead, so a presenter can never skip past a reveal.
##
## The 1920×1080 canvas is fixed; position things in those pixels.

const W := 1920.0
const H := 1080.0
const MARGIN := 96.0

var data: GameData
## All slides in the show, in order (the finale reads everyone's awards).
var ceremony: Array = []

var stage: Control
var _steps: Array[Callable] = []
var _running: Tween
var _on_skip: Callable


# ── Override these ───────────────────────────────────────────────────

func build() -> void:
	pass


## [{title, winners: [player tags], stat}] — used by the finale.
func get_awards() -> Array:
	return []


# ── Called by the show ───────────────────────────────────────────────

func enter() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if stage:
		stage.queue_free()
	stage = Control.new()
	stage.size = Vector2(W, H)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	_steps.clear()
	_running = null
	_reset_build_state()
	build()


## Going back to a slide builds it again. Lists, maps and node links
## that build() keeps in a subclass's private vars (_rows, _tiles...)
## would still point at the old, freed nodes, so they are emptied first.
## Plain numbers and flags are left for build() to set.
func _reset_build_state() -> void:
	var script: Script = get_script()
	var base := script
	while base.get_base_script():
		base = base.get_base_script()
	var own := {}
	for prop in base.get_script_property_list():
		own[prop["name"]] = true
	for prop in script.get_script_property_list():
		var key: String = prop["name"]
		if not key.begins_with("_") or own.has(key) \
				or not (prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var value = get(key)
		match typeof(value):
			TYPE_ARRAY, TYPE_DICTIONARY:
				value.clear()
			TYPE_OBJECT:
				set(key, null)  # may already be freed with the old stage


## Returns false when the slide has nothing left to show.
func advance() -> bool:
	if _running and _running.is_valid() and _running.is_running():
		_running.kill()
		_running = null
		if _on_skip.is_valid():
			_on_skip.call()
		return true
	if _steps.is_empty():
		return false
	var step: Callable = _steps.pop_front()
	step.call()
	return true


# ── Helpers for subclasses ───────────────────────────────────────────

func add_step(fn: Callable) -> void:
	_steps.append(fn)


## Registers a long animation. A click while it runs calls on_skip
## (which should jump straight to the end state) instead of moving on.
func play(tween: Tween, on_skip: Callable) -> void:
	_running = tween
	_on_skip = on_skip


func tween() -> Tween:
	return stage.create_tween()


func add(node: Node) -> Node:
	stage.add_child(node)
	return node


## The standard award heading: small eyebrow, big title, gold rule, subtitle.
## Returns the y position just below it.
func add_header(eyebrow: String, title: String, subtitle: String, y := 64.0) -> float:
	var e := UI.eyebrow(eyebrow, 15, Config.GOLD)
	e.position = Vector2(MARGIN, y)
	e.size = Vector2(W - MARGIN * 2, 24)
	add(e)
	var t := UI.label(title.to_upper(), UI.Face.DISPLAY, 58, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 8)
	t.material = UI.gold_material()
	t.position = Vector2(MARGIN - 4, y + 26)
	t.size = Vector2(W - MARGIN * 2, 84)
	add(t)
	var o := Ornament.new(520)
	o.position = Vector2(MARGIN, y + 114)
	add(o)
	var s := UI.label(subtitle, UI.Face.ITALIC, 32, Config.SAND_DIM)
	s.position = Vector2(MARGIN, y + 132)
	s.size = Vector2(W - MARGIN * 2, 44)
	add(s)
	return y + 186.0


## Award cards for this slide, one per click, in the order given.
func add_award_card_steps(awards: Array) -> void:
	var card := AwardCard.new(data)
	add(card)
	for a in awards:
		add_step(func(): card.show_award(a))
