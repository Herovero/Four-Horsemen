extends Node2D

@onready var loading_transition = $loading_transition

func _ready():
	loading_transition.play()
	await get_tree().create_timer(4).timeout
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
