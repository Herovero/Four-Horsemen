extends Node2D

# Variables
#var hp: int = 30
var pudding_hp: int = 3
var bomb_hp: int = 3
var virus_hp: int = 3
var fries_hp: int = 3

@onready var bat_label = $bat_labels
@onready var bat_animation = $bat_animation

# Signal to notify when zombie is destroyed
signal bat_destroyed

func _ready():
	bat_label.bbcode_enabled = true
	update_bat_label()
	# Connect the animation_finished signal
	if bat_animation:
		bat_animation.animation_finished.connect(_on_animation_finished)

func update_bat_label():
	# If the bat label doesn't exist or is hidden, we don't need to update it
	if not bat_label or not bat_label.is_visible():
		return
		
	var images = ["res://Sprites/Pudding.png", "res://Sprites/Nuclear bomb.png", "res://Sprites/virus.png", "res://Sprites/Mcdonald.png"]
	var bbcode = ""
	
	# Check each HP value and build the bbcode accordingly
	var all_hp_zero = true  # Flag to check if all HPs are zero
	
	if pudding_hp > 0:
		bbcode += "[img=50]" + images[0] + "[/img] " + str(pudding_hp)
		all_hp_zero = false
	if bomb_hp > 0:
		bbcode += "[img=50]" + images[1] + "[/img] " + str(bomb_hp)
		all_hp_zero = false
	if virus_hp > 0:
		bbcode += "[img=50]" + images[2] + "[/img] " + str(virus_hp)
		all_hp_zero = false
	if fries_hp > 0:
		bbcode += "[img=50]" + images[3] + "[/img] " + str(fries_hp)
		all_hp_zero = false
	
	# If all HPs are zero, display a "Zombie Dead" message
	if all_hp_zero:
		bbcode = "[center][b]Zombie Dead[/b][/center]"
	
	# Set the bbcode text to update the label only if it's still valid and visible
	if bat_label and bat_label.is_visible():
		bat_label.bbcode_text = bbcode

func take_damage(amount, hero_type):
	print("zombie take damage")
	
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
				
		update_bat_label()

		# Check if all HP types are 0 to trigger death animation
		if pudding_hp == 0 and bomb_hp == 0 and virus_hp == 0 and fries_hp == 0:
			emit_signal("bat_destroyed", self)  # Ensure signal is emitted
		   # All HPs depleted; start death sequence
			bat_label.hide()
			bat_animation.play("death")
		else:
			bat_animation.play(animation_type)

func bat_attack():
	bat_animation.play("attack")
	
func _on_animation_finished(anim_name):
	if anim_name == "death":
		print("Bat has died. Removing from scene.")
		# Remove both the bat and its label
		emit_signal("bat_destroyed", self)  # Ensure signal is emitted
		queue_free()
