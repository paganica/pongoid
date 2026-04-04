extends Node2D

var score_left := 0
var score_right := 0

@onready var ball = $Ball
@onready var score_label = $CanvasLayer/ScoreLabel

func _ready():
	update_score()

func update_score():
	score_label.text = str(score_left) + " : " + str(score_right)

func reset_ball(direction):
	ball.position = get_viewport_rect().size / 2
	ball.reset(direction)

func _on_goal_left_body_entered(body):
	if body.name == "Ball":
		score_right += 1
		update_score()
		check_win()
		await get_tree().create_timer(2.0).timeout
		reset_ball(1)

func _on_goal_right_body_entered(body):
	if body.name == "Ball":
		score_left += 1
		update_score()
		check_win()
		await get_tree().create_timer(2.0).timeout
		reset_ball(-1)
		
func check_win():
	if score_left >= GameSettings.win_score:
		end_game("Left Player Wins!")
	elif score_right >= GameSettings.win_score:
		end_game("Right Player Wins!")
		
func end_game(message):
	print(message)  
	# stop ball
	ball.velocity = Vector2.ZERO 
	# optional: stop game logic
	set_process(false)
