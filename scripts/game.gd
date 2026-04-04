extends Node2D

var score_left := 0
var score_right := 0

@onready var ball = $Ball
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var win_screen = $CanvasLayer/WinScreen
@onready var win_label = $CanvasLayer/WinScreen/WinLabel

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
		
func check_win() -> bool:
	if score_left >= GameSettings.win_score:
		end_game("Player 1 Wins!", Color.BLUE)
		return true
	elif score_right >= GameSettings.win_score:
		end_game("Player 2 Wins!", Color.DARK_RED)
		return true
	return false
		
func end_game(message, color):
	# stop ball
	ball.velocity = Vector2.ZERO 
	# optional: stop game logic
	set_process(false)
	win_label.text = message
	win_label.add_theme_color_override("font_color", color)
	win_screen.visible = true
