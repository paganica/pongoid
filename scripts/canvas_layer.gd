extends CanvasLayer

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	$PauseScreen.visible = false
	



func _on_pause_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
