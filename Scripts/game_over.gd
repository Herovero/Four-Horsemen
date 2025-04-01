extends Node2D

@onready var game_over_animation = $game_over_animation
@onready var we_will_be_right_back = $"We'll be right back"
@onready var to_be_continued = $"To be continued"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_yes_button_pressed():
	game_over_animation.play("yes_button")
	we_will_be_right_back.play()
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")

func _on_no_button_pressed():
	game_over_animation.play("no_button")
	to_be_continued.play()
	await get_tree().create_timer(7).timeout
	get_tree().quit()
