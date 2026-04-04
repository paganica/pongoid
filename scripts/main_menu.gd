extends Control

var is_two_player := false
var difficulties = ["easy", "medium", "hard"]
var current_difficulty_index = 1
var sound_on := true

@onready var player_button = $VBoxMenu/PlayerModeButton
@onready var sound_button = $VBoxMenu/SoundButton
@onready var difficulty_button = $VBoxMenu/DifficultyButton
@onready var win_score_button = $VBoxMenu/WinScore
var win_scores = [3, 5, 10]
var current_win_index = 0

func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_player_mode_button_pressed():
	is_two_player = !is_two_player
	GameSettings.is_two_player = is_two_player
	
	if is_two_player:
		player_button.text = "2 Players"
	else:
		player_button.text = "1 Player"

func _on_difficulty_button_pressed():
	current_difficulty_index = (current_difficulty_index + 1) % difficulties.size()
	
	var diff = difficulties[current_difficulty_index]
	GameSettings.ai_difficulty = diff 
	difficulty_button.text = diff.capitalize()
	
func _on_sound_button_pressed() -> void:
	sound_on = !sound_on
	
	if sound_on:
		sound_button.text = "Sound:  ON"
	else:
		sound_button.text = "Sound: OFF"

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_win_score_pressed() -> void:
	current_win_index = (current_win_index + 1) % win_scores.size()
	var score = win_scores[current_win_index]
	GameSettings.win_score = score
	
	win_score_button.text = "Win Score: " + str(score)
