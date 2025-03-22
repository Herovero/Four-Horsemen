extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(86).timeout 
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
