extends Node2D

const BrickScene = preload("res://scenes/brick.tscn")
const MultiBallScene = preload("res://scenes/multi_ball.tscn")
const BRICK_SPAWN_INTERVAL = 8.0
const BRICK_SPAWN_INITIAL_DELAY = 0.0
const MAX_BRICKS = 3
const PADDLE_SIZE_BONUS = 40.0
const PADDLE_SPEED_BONUS = 50.0

var score_left := 0
var score_right := 0
var game_over := false
var spawn_timer := BRICK_SPAWN_INITIAL_DELAY
var active_bricks := []
var extra_balls := []

@onready var ball = $Ball
@onready var paddle_left = $PaddleLeft
@onready var paddle_right = $PaddleRight
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var win_screen = $CanvasLayer/WinScreen
@onready var win_label = $CanvasLayer/WinScreen/WinLabel

func _ready():
	update_score()

func _process(delta):
	if game_over:
		return
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = BRICK_SPAWN_INTERVAL
		if active_bricks.size() < MAX_BRICKS:
			spawn_brick()

func update_score():
	score_label.text = str(score_left) + " : " + str(score_right)

func reset_ball(direction):
	ball.position = get_viewport_rect().size / 2
	ball.reset(direction)

func _on_goal_left_body_entered(body):
	if body == ball:
		score_right += 1
		update_score()
		if check_win():
			return
		ball.visible = false
		ball.set_physics_process(false)
		await wait_for_extra_balls()
		await get_tree().create_timer(2.0).timeout
		ball.visible = true
		ball.set_physics_process(true)
		reset_ball(1)
	elif body is CharacterBody2D and extra_balls.has(body):
		extra_balls.erase(body)
		body.queue_free()
		score_right += 1
		update_score()
		check_win()

func _on_goal_right_body_entered(body):
	if body == ball:
		score_left += 1
		update_score()
		if check_win():
			return
		ball.visible = false
		ball.set_physics_process(false)
		await wait_for_extra_balls()
		await get_tree().create_timer(2.0).timeout
		ball.visible = true
		ball.set_physics_process(true)
		reset_ball(-1)
	elif body is CharacterBody2D and extra_balls.has(body):
		extra_balls.erase(body)
		body.queue_free()
		score_left += 1
		update_score()
		check_win()

func wait_for_extra_balls():
	while extra_balls.size() > 0:
		await get_tree().process_frame

func spawn_brick():
	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y
	var center_x = screen_width / 2.0
	var brick_w = screen_width / 32.0
	var brick_h = screen_height / 16.0
	var padding = 20.0
	var max_attempts = 20
	var candidate_pos = Vector2.ZERO
	var found = false

	for attempt in range(max_attempts):
		candidate_pos = Vector2(
			randf_range(center_x - 200.0, center_x + 200.0),
			randf_range(50.0, screen_height - 50.0)
		)
		var overlapping = false
		for existing_brick in active_bricks:
			if not is_instance_valid(existing_brick):
				continue
			var dist_x = abs(candidate_pos.x - existing_brick.position.x)
			var dist_y = abs(candidate_pos.y - existing_brick.position.y)
			if dist_x < brick_w + padding and dist_y < brick_h + padding:
				overlapping = true
				break
		if not overlapping:
			found = true
			break

	if not found:
		return

	var brick = BrickScene.instantiate()
	brick.position = candidate_pos
	add_child(brick)
	active_bricks.append(brick)

func brick_hit(brick):
	active_bricks.erase(brick)

	var last_hitter = _get_last_hitter()
	if last_hitter == null:
		return

	var hitter_paddle = last_hitter
	var opponent_paddle = paddle_right if hitter_paddle == paddle_left else paddle_left

	match brick.brick_type:
		0: apply_timed_effect(hitter_paddle, PADDLE_SIZE_BONUS, 0.0)
		1: apply_timed_effect(hitter_paddle, 0.0, PADDLE_SPEED_BONUS)
		2: apply_timed_effect(opponent_paddle, -PADDLE_SIZE_BONUS, 0.0)
		3: apply_timed_effect(opponent_paddle, 0.0, -PADDLE_SPEED_BONUS)
		4: spawn_multiballs()
		5: reset_paddles()
		
func _get_last_hitter():
	if ball.last_hitter != null:
		return ball.last_hitter
	for b in extra_balls:
		if is_instance_valid(b) and b.last_hitter != null:
			return b.last_hitter
	return null

func spawn_multiballs():
	var screen_height = get_viewport_rect().size.y
	var angles = [randf_range(-PI / 2, 0), randf_range(0, PI / 2)]  # one up, one down
	for i in range(2):
		var mb = MultiBallScene.instantiate()
		mb.radius = screen_height / 60.0
		mb.position = ball.position + Vector2(0, (i * 2 - 1) * mb.radius * 3)  # offset up/down
		mb.speed = ball.speed
		mb.velocity = Vector2(cos(angles[i]), sin(angles[i])) * ball.speed
		add_child(mb)
		extra_balls.append(mb)
		
func apply_timed_effect(paddle, size_delta: float, speed_delta: float):
	var min_height = get_viewport_rect().size.y / 12.0
	var max_height = get_viewport_rect().size.y / 4.0
	var min_speed = 300.0
	var max_speed = 400.0
	var new_height = clamp(paddle.base_height + size_delta, min_height, max_height)
	var new_speed = clamp(paddle.base_speed + speed_delta, min_speed, max_speed)
	paddle.apply_effect(new_height, new_speed)
	
func check_win() -> bool:
	if score_left >= GameSettings.win_score:
		end_game("Player 2 Wins!", Color.DARK_RED)
		return true
	elif score_right >= GameSettings.win_score:
		end_game("Player 1 Wins!", Color.BLUE)
		return true
	return false

func end_game(message, color):
	game_over = true

	ball.velocity = Vector2.ZERO
	ball.set_physics_process(false)
	ball.visible = false
	for b in extra_balls:
		if is_instance_valid(b):
			b.queue_free()
	extra_balls.clear()
	
	for brick in active_bricks:
		if is_instance_valid(brick):
			brick.queue_free()
	active_bricks.clear()

	paddle_left.set_physics_process(false)
	paddle_right.set_physics_process(false)

	$GoalLeft.call_deferred("set_monitoring", false)
	$GoalRight.call_deferred("set_monitoring", false)

	win_label.text = message
	win_label.add_theme_color_override("font_color", color)
	win_screen.visible = true

func reset_paddles():
	for paddle in [paddle_left, paddle_right]:
		paddle.clear_effect()
