extends CharacterBody2D

@export var speed := 350
var start_x
var paddle_height
@onready var collision = $CollisionShape2D
@onready var ball = get_parent().get_node("Ball")
var reaction_timer := 0.0
var target_y := 0.0

func _ready():
	start_x = position.x

	var screen_height = get_viewport_rect().size.y
	paddle_height = screen_height / 8
	target_y = screen_height / 2

	collision.shape.size.y = paddle_height
	queue_redraw()

func _draw():
	var width = 20
	draw_rect(Rect2(-width/2, -paddle_height/2, width, paddle_height), Color.DARK_RED)

func _physics_process(delta):
	var screen_height = get_viewport_rect().size.y
	var half_height = paddle_height / 2

	if GameSettings.is_two_player:
		# --- PLAYER CONTROL ---
		var direction = 0
		if Input.is_action_pressed("p1_up"):
			direction -= 1
		if Input.is_action_pressed("p1_down"):
			direction += 1
		position.y += direction * speed * delta
		position.y = clamp(position.y, half_height + 15, screen_height - half_height - 15)
		position.x = start_x
		return

	# --- AI CONTROL ---
	var ai_speed: float
	var reaction_time: float
	var error_margin: float

	match GameSettings.ai_difficulty:
		"easy":
			ai_speed = 350
			reaction_time = 0.5
			error_margin = 50
		"medium":
			ai_speed = 350
			reaction_time = 0.3
			error_margin = 30
		"hard":
			ai_speed = 350
			reaction_time = 0.1
			error_margin = 10

	# Update target_y on a delay (reaction time)
	reaction_timer -= delta
	if reaction_timer <= 0:
		reaction_timer = reaction_time

		if ball.velocity.x > 0:
			# Ball is coming towards AI — predict landing position
			match GameSettings.ai_difficulty:
				"easy":
					# Easy: just aim at current ball position, no prediction
					target_y = ball.position.y + randf_range(-error_margin, error_margin)
				"medium", "hard":
					# Medium/Hard: predict where ball will be when it reaches paddle
					target_y = predict_ball_y(screen_height) + randf_range(-error_margin, error_margin)
		else:
			# Ball moving away — return toward center (with some laziness on easy)
			match GameSettings.ai_difficulty:
				"easy":
					target_y = position.y  # stay put on easy
				"medium":
					target_y = screen_height / 2
				"hard":
					target_y = screen_height / 2

	# Move toward target
	var direction = 0
	if ball.velocity.x > 0 or GameSettings.ai_difficulty != "easy":
		if target_y < position.y - 10:
			direction = -1
		elif target_y > position.y + 10:
			direction = 1

	position.y += direction * ai_speed * delta
	position.y = clamp(position.y, half_height + 15, screen_height - half_height - 15)
	position.x = start_x

func predict_ball_y(screen_height: float) -> float:
	# Estimate ball Y position when it reaches the paddle's X
	var distance_x = start_x - ball.position.x
	if ball.velocity.x <= 0:
		return screen_height / 2  # ball not coming, return center

	var time_to_reach = distance_x / ball.velocity.x
	var predicted_y = ball.position.y + ball.velocity.y * time_to_reach

	# Simulate bouncing off top and bottom walls
	var effective_height = screen_height - 30  # account for mantinel offset
	predicted_y = bounce_simulate(predicted_y, 15, effective_height)

	return predicted_y

func bounce_simulate(y: float, top: float, bottom: float) -> float:
	# Fold the predicted Y back into the playfield accounting for wall bounces
	var range_h = bottom - top
	y = y - top
	if y < 0:
		y = -y
	var cycles = int(y / range_h)
	y = fmod(y, range_h)
	if cycles % 2 == 1:
		y = range_h - y
	return y + top
