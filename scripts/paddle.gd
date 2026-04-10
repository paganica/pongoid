extends CharacterBody2D

@export var speed := 350
@export var is_left_paddle := false  # set this in the editor per paddle instance
@onready var collision = $CollisionShape2D
@onready var ball = get_parent().get_node("Ball")

var start_x
var paddle_height
# AI state
var reaction_timer := 0.0
var target_y := 0.0

# variables for brick effects
var base_height: float  # store original height
var base_speed: float   # store original speed
var effect_timer: float = 0.0
var has_effect: bool = false

func _ready():
	start_x = position.x

	var screen_height = get_viewport_rect().size.y
	paddle_height = screen_height / 8.0
	target_y = screen_height / 2.0
	base_height = paddle_height  # store base values
	base_speed = speed

	collision.shape.size.y = paddle_height
	queue_redraw()

func _draw():
	var width = 20
	var color = Color.DARK_RED if is_left_paddle else Color.BLUE
	draw_rect(Rect2(-width/2.0, -paddle_height/2.0, width, paddle_height), color)

func _physics_process(delta):
	var screen_height = get_viewport_rect().size.y
	var half_height = paddle_height / 2
	var direction = 0

# count down active effect
	if has_effect:
		effect_timer -= delta
		if effect_timer <= 0:
			clear_effect()

	if is_left_paddle:
		# --- LEFT PADDLE: PLAYER 2 or AI ---
		if GameSettings.is_two_player:
			# --- PLAYER 2 CONTROL (W/S keys) ---
			if Input.is_action_pressed("p2_up"):
				direction -= 1
			if Input.is_action_pressed("p2_down"):
				direction += 1
		else:
			# --- AI CONTROL ---
			direction = _get_ai_direction(delta, screen_height)

	else:
		# --- RIGHT PADDLE: PLAYER 1 (arrow keys) always ---
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

	reaction_timer -= delta
	if reaction_timer <= 0:
		reaction_timer = reaction_time

		if ball.velocity.x < 0:  # ball coming towards left paddle
			match GameSettings.ai_difficulty:
				"easy":
					target_y = ball.position.y + randf_range(-error_margin, error_margin)
				"medium", "hard":
					target_y = predict_ball_y(screen_height) + randf_range(-error_margin, error_margin)
		else:
			match GameSettings.ai_difficulty:
				"easy":
					target_y = position.y  # stay put
				"medium", "hard":
					target_y = screen_height / 2  # return to center

	if target_y < position.y - 10:
		return -1
	elif target_y > position.y + 10:
		return 1
	return 0

func predict_ball_y(screen_height: float) -> float:
	var distance_x = ball.position.x - start_x  # flipped for left paddle
	if ball.velocity.x >= 0:                     # flipped: ball moving away
		return screen_height / 2

	var time_to_reach = distance_x / -ball.velocity.x  # use absolute speed
	var predicted_y = ball.position.y + ball.velocity.y * time_to_reach

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
