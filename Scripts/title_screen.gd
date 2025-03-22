extends Node2D

@onready var start_button = $start_button
@onready var transition = $transition

# Called when the node enters the scene tree for the first time.
func _ready():
	start_button.connect("mouse_entered", _on_start_button_mouse_entered)
	start_button.connect("pressed", _on_start_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_start_button_mouse_entered():
	start_button.texture_normal = preload("res://Sprites/Start button2.png")  # Change to your hover texture

func _on_start_button_pressed():
	transition.play("switch2difficulties")
	
