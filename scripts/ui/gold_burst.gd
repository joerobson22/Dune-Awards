class_name GoldBurst
extends CPUParticles2D
## A one-shot shower of gold sparks. Add it anywhere; it frees itself.
##   parent.add_child(GoldBurst.new(Rect2(...)))

func _init(area: Rect2, sparks := 160) -> void:
	position = area.get_center()
	one_shot = true
	explosiveness = 0.92
	amount = sparks
	lifetime = 1.8
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = area.size * 0.5
	direction = Vector2(0, -1)
	spread = 160.0
	initial_velocity_min = 90.0
	initial_velocity_max = 360.0
	gravity = Vector2(0, 240)
	damping_min = 20.0
	damping_max = 60.0
	scale_amount_min = 0.25
	scale_amount_max = 0.7
	texture = UI.soft_dot(24)
	var ramp := Gradient.new()
	ramp.set_color(0, Config.GOLD_BRIGHT)
	ramp.set_color(1, Color(Config.GOLD, 0.0))
	ramp.add_point(0.45, Config.GOLD)
	color_ramp = ramp
	finished.connect(queue_free)


func _ready() -> void:
	emitting = true
