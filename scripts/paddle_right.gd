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

	collision.shape.size.y = paddle_height

	queue_redraw()

func _draw():
	var width = 20
	draw_rect(Rect2(-width/2, -paddle_height/2, width, paddle_height), Color.DARK_RED)

func _physics_process(delta):
	var direction = 0
	
	if Input.is_action_pressed("p1_up"):
		direction -= 1
	if Input.is_action_pressed("p1_down"):
		direction += 1

	var screen_height = get_viewport_rect().size.y
	var half_height = paddle_height / 2

	position.y += direction * speed * delta
	position.y = clamp(position.y, half_height + 15, screen_height - half_height - 15)
	position.x = start_x

	if not GameSettings.is_two_player:
	# SETTINGS BASED ON DIFFICULTY
		var ai_speed
		var reaction_time
		var error_margin

		match GameSettings.ai_difficulty:
			"easy":
				ai_speed = 350
				reaction_time = 0.4
				error_margin = 40
			"medium":
				ai_speed = 350
				reaction_time = 0.2
				error_margin = 20
			"hard":
				ai_speed = 350
				reaction_time = 0.1
				error_margin = 10

	# REACTION DELAY
		reaction_timer -= delta

		if reaction_timer <= 0:
			reaction_timer = reaction_time
		
		# AI picks a target with some inaccuracy
		target_y = ball.position.y + randf_range(-error_margin, error_margin)

	# MOVE TOWARDS TARGET
		if ball.velocity.x > 0:
			if target_y < position.y - 10:
				direction = -1
			elif target_y > position.y + 10:
				direction = 1

		position.y += direction * ai_speed * delta
		position.y = clamp(position.y, half_height + 15, screen_height - half_height - 15)
		position.x = start_x
