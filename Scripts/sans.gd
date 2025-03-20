extends Node2D

# Variables
#var hp: int = 30
var pudding_hp: float = 0.01
var bomb_hp: float = 0.01
var virus_hp: float = 0.01
var fries_hp: float = 0.01

@onready var sans_label = $sans_labels
@onready var sans_animation = $sans_animation

# Signal to notify when sans is destroyed
signal sans_destroyed

func _ready():
	sans_label.bbcode_enabled = true
	update_sans_label()
	# Connect the animation_finished signal
	if sans_animation:
		sans_animation.animation_finished.connect(_on_animation_finished)

func sans_appear():
	sans_animation.play("chatbox")

func get_rect() -> Rect2:
	# Adjust the size of the rectangle based on the enemy's sprite size
	var rect_size = Vector2(100, 100)  # Adjust this to match your enemy's size
	return Rect2(position - rect_size / 2, rect_size)

func update_sans_label():
	# If the sans label doesn't exist or is hidden, we don't need to update it
	if not sans_label or not sans_label.is_visible():
		return
		
	var images = ["res://Sprites/Pudding.png", "res://Sprites/Nuclear bomb.png", "res://Sprites/virus.png", "res://Sprites/Mcdonald.png"]
	var bbcode = ""
	
	 # Check each HP value and build the bbcode accordingly
	var all_hp_zero = true  # Flag to check if all HPs are zero
	
	if pudding_hp > 0:
		bbcode += "[img=50]" + images[0] + "[/img] " + str(round(pudding_hp * 100) / 100) + "\n"
		all_hp_zero = false
	if bomb_hp > 0:
		bbcode += "[img=50]" + images[1] + "[/img] " + str(round(bomb_hp * 100) / 100) + "\n"
		all_hp_zero = false
	if virus_hp > 0:
		bbcode += "[img=50]" + images[2] + "[/img] " + str(round(virus_hp * 100) / 100) + "\n"
		all_hp_zero = false
	if fries_hp > 0:
		bbcode += "[img=50]" + images[3] + "[/img] " + str(round(fries_hp * 100) / 100) + "\n"
		all_hp_zero = false
	
	# If all HPs are zero, display a "Sans Dead" message
	if all_hp_zero:
		bbcode = "[center][b]Sans Dead[/b][/center]"
	
	# Set the bbcode text to update the label only if it's still valid and visible
	if sans_label and sans_label.is_visible():
		sans_label.bbcode_text = bbcode

func take_damage(amount, hero_type):
	print("sans take damage")
	
	# Check if the HP for the hero type is already 0
	var hp_before_damage = 0
	var animation_type = "attacked"  # Default animation when HP is above 0
	
	match hero_type:
		"pudding":
			hp_before_damage = pudding_hp
		"bomb":
			hp_before_damage = bomb_hp
		"virus":
			hp_before_damage = virus_hp
		"fries":
			hp_before_damage = fries_hp
	
	# If the HP before the attack is 0, trigger a different animation
	if hp_before_damage == 0:
		animation_type = "attacked_2"
	
	# Apply damage only if the HP is above 0
	if amount > 0:
		match hero_type:
			"pudding":
				pudding_hp -= amount
				if pudding_hp < 0:
					pudding_hp = 0 # Prevent going below 0
			"bomb":
				bomb_hp -= amount
				if bomb_hp < 0:
					bomb_hp = 0  # Prevent going below 0
			"virus":
				virus_hp -= amount
				if virus_hp < 0:
					virus_hp = 0  # Prevent going below 0
			"fries":
				fries_hp -= amount
				if fries_hp < 0:
					fries_hp = 0  # Prevent going below 0
				
		update_sans_label()

		# Check if all HP types are 0 to trigger death animation
		if pudding_hp == 0 and bomb_hp == 0 and virus_hp == 0 and fries_hp == 0:
			emit_signal("sans_destroyed", self)  # Ensure signal is emitted
		   # All HPs depleted; start death sequence
			sans_label.hide()
			sans_animation.play("death")
		else:
			sans_animation.play(animation_type)

func sans_attack():
	sans_animation.play("attack")
	await sans_animation.animation_finished

func _on_animation_finished(anim_name):
	if anim_name == "death":
		print("Sans has died. Removing from scene.")
		# Remove both the sans and its label
		emit_signal("sans_destroyed", self)  # Ensure signal is emitted
		queue_free()
