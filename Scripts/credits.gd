extends VideoStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(56).timeout
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
