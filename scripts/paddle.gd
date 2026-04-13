extends CharacterBody2D

@export var speed := 350
@export var is_left_paddle := false
@onready var collision = $CollisionShape2D
@onready var game = get_parent()

var start_x
var paddle_height
var reaction_timer := 0.0
var target_y := 0.0

var base_height: float
var base_speed: float
var effect_timer: float = 0.0
var has_effect: bool = false

func _ready():
	start_x = position.x
	var screen_height = get_viewport_rect().size.y
	paddle_height = screen_height / 8.0
	target_y = screen_height / 2.0
	base_height = paddle_height
	base_speed = speed
	collision.shape.size.y = paddle_height
	queue_redraw()

func _draw():
	var width = 20
	var color = Color.DARK_RED if is_left_paddle else Color.BLUE
	draw_rect(Rect2(-width/2.0, -paddle_height/2.0, width, paddle_height), color)

func _get_target_ball():
	# build list of all active balls
	var all_balls = []
	if is_instance_valid(game.ball) and game.ball.visible:
		all_balls.append(game.ball)
	for b in game.extra_balls:
		if is_instance_valid(b):
			all_balls.append(b)

	if all_balls.is_empty():
		return null

	# pick the ball moving towards this paddle and closest on X
	var best = null
	var best_dist = INF
	for b in all_balls:
		var coming_towards = b.velocity.x < 0 if is_left_paddle else b.velocity.x > 0
		if coming_towards:
			var dist = abs(b.position.x - start_x)
			if dist < best_dist:
				best_dist = dist
				best = b

	# fallback: no ball coming towards us, just pick closest
	if best == null:
		for b in all_balls:
			var dist = abs(b.position.x - start_x)
			if dist < best_dist:
				best_dist = dist
				best = b

	return best

func _physics_process(delta):
	var screen_height = get_viewport_rect().size.y
	var half_height = paddle_height / 2
	var direction = 0

	if has_effect:
		effect_timer -= delta
		if effect_timer <= 0:
			clear_effect()

	if is_left_paddle:
		if GameSettings.is_two_player:
			if Input.is_action_pressed("p2_up"):
				direction -= 1
			if Input.is_action_pressed("p2_down"):
				direction += 1
		else:
			direction = _get_ai_direction(delta, screen_height)
	else:
		if Input.is_action_pressed("p1_up"):
			direction -= 1
		if Input.is_action_pressed("p1_down"):
			direction += 1

	position.y += direction * speed * delta
	position.y = clamp(position.y, half_height + 15, screen_height - half_height - 15)
	position.x = start_x

func _get_ai_direction(delta: float, screen_height: float) -> int:
	var reaction_time: float
	var error_margin: float

	match GameSettings.ai_difficulty:
		"easy":
			reaction_time = 0.5
			error_margin = 40
		"medium":
			reaction_time = 0.35
			error_margin = 30
		"hard":
			reaction_time = 0.15
			error_margin = 15

	var target_ball = _get_target_ball()
	if target_ball == null:
		return 0

	reaction_timer -= delta
	if reaction_timer <= 0:
		reaction_timer = reaction_time
		if target_ball.velocity.x < 0:
			match GameSettings.ai_difficulty:
				"easy":
					target_y = target_ball.position.y + randf_range(-error_margin, error_margin)
				"medium", "hard":
					target_y = predict_ball_y(screen_height, target_ball) + randf_range(-error_margin, error_margin)
		else:
			match GameSettings.ai_difficulty:
				"easy":
					target_y = position.y
				"medium", "hard":
					target_y = screen_height / 2

	if target_y < position.y - 10:
		return -1
	elif target_y > position.y + 10:
		return 1
	return 0

func predict_ball_y(screen_height: float, target_ball) -> float:
	var distance_x = target_ball.position.x - start_x
	if target_ball.velocity.x >= 0:
		return screen_height / 2

	var time_to_reach = distance_x / -target_ball.velocity.x
	var predicted_y = target_ball.position.y + target_ball.velocity.y * time_to_reach

	var effective_height = screen_height - 30
	predicted_y = bounce_simulate(predicted_y, 15, effective_height)
	return predicted_y

func bounce_simulate(y: float, top: float, bottom: float) -> float:
	var range_h = bottom - top
	y = y - top
	if y < 0:
		y = -y
	var cycles = int(y / range_h)
	y = fmod(y, range_h)
	if cycles % 2 == 1:
		y = range_h - y
	return y + top

func apply_effect(new_height: float, new_speed: float):
	paddle_height = new_height
	collision.shape.size.y = paddle_height
	speed = new_speed
	has_effect = true
	effect_timer = 15.0
	queue_redraw()

func clear_effect():
	has_effect = false
	effect_timer = 0.0
	paddle_height = base_height
	collision.shape.size.y = paddle_height
	speed = base_speed
	queue_redraw()
