extends Node2D

@onready var start_button = $start_button
@onready var exit_button = $exit_button
@onready var settings = $Settings
@onready var credit_icon = $credit_icon
@onready var credits = $credits
@onready var transition = $transition
@onready var skill_issue_transition = $injustice/skill_issue_transition
@onready var sweaty_gamer_transition = $sweaty_gamer/sweaty_gamer_transition
@onready var midwest_transition = $midwest/midwest_transition
@onready var gigachad_transition = $gigachad/gigachad_transition

@onready var injustice = $injustice
@onready var midwest = $midwest
@onready var sweaty_gamer = $sweaty_gamer
@onready var gigachad = $gigachad

var switched2difficulties = false
var showed_settings = false

# Called when the node enters the scene tree for the first time.
func _ready():
	start_button.connect("pressed", _on_start_button_pressed)
	settings.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_start_button_pressed():
	transition.play("switch2difficulties")
	await get_tree().create_timer(2.2).timeout
	switched2difficulties = true

func _on_exit_button_pressed():
	get_tree().quit()

func _on_settings_icon_pressed():
	settings.show()
	showed_settings = true

func _on_credit_icon_pressed():
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")

func _input(event):
	if switched2difficulties == true and event.is_action_pressed("ui_cancel"):  # ESC key default action
		transition.play("switch2title")
		switched2difficulties = false
	elif showed_settings == true and event.is_action_pressed("ui_cancel"):
		settings.hide()
	
func _on_skill_issue_button_mouse_entered():
	injustice.play()
	skill_issue_transition.play("injustice")

func _on_skill_issue_button_mouse_exited():
	skill_issue_transition.play("injustice2")
	await get_tree().create_timer(0.3).timeout
	injustice.stop()

func _on_skill_issue_button_pressed():
	Global.difficulty = "Skill_issue"
	get_tree().change_scene_to_file("res://Scenes/loading.tscn")

func _on_tryhard_button_mouse_entered():
	sweaty_gamer.play()
	sweaty_gamer_transition.play("sweaty_gamer")

func _on_tryhard_button_mouse_exited():
	sweaty_gamer_transition.play("sweaty_gamer2")
	await get_tree().create_timer(0.3).timeout
	sweaty_gamer.stop()

func _on_tryhard_button_pressed():
	Global.difficulty = "Tryhard"
	get_tree().change_scene_to_file("res://Scenes/loading.tscn")
	
func _on_midwest_button_mouse_entered():
	midwest.play()
	midwest_transition.play("midwest")

func _on_midwest_button_mouse_exited():
	midwest_transition.play("midwest2")
	await get_tree().create_timer(0.3).timeout
	midwest.stop()

func _on_midwest_button_pressed():
	Global.difficulty = "Midwest"
	get_tree().change_scene_to_file("res://Scenes/loading.tscn")

func _on_gigachad_button_mouse_entered():
	gigachad.play()
	gigachad_transition.play("gigachad")

func _on_gigachad_button_mouse_exited():
	gigachad_transition.play("gigachad2")
	await get_tree().create_timer(0.3).timeout
	gigachad.stop()

func _on_gigachad_button_pressed():
	Global.difficulty = "Gigachad"
	get_tree().change_scene_to_file("res://Scenes/loading.tscn")
