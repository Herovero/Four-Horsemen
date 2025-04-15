extends Node2D

# Variables
#var hp: int = 30
var pudding_hp: float = 30
var bomb_hp: float = 10
var virus_hp: float = 30
var fries_hp: float = 10

@onready var giratina_label = $giratina_labels
@onready var giratina_animation = $giratina_animation

# Signal to notify when giratina is destroyed
signal giratina_destroyed

func _ready():
	match Global.difficulty:
		"Debug":
			pudding_hp = 5
			bomb_hp = 8
			virus_hp = 8
			fries_hp = 5
		"Skill_issue":
			pudding_hp = 5
			bomb_hp = 8
			virus_hp = 8
			fries_hp = 5
		"Midwest":
			pudding_hp = 8
			bomb_hp = 12
			virus_hp = 12
			fries_hp = 8
		"Tryhard":
			pudding_hp = 8
			bomb_hp = 12
			virus_hp = 12
			fries_hp = 8
		"Gigachad":
			pudding_hp = 10
			bomb_hp = 16
			virus_hp = 16
			fries_hp = 10
	giratina_label.bbcode_enabled = true
	update_giratina_label()
	# Connect the animation_finished signal
	if giratina_animation:
		giratina_animation.animation_finished.connect(_on_animation_finished)

func giratina_appear():
	giratina_animation.play("appear")

func get_rect() -> Rect2:
	# Adjust the size of the rectangle based on the enemy's sprite size
	var rect_size = Vector2(100, 100)  # Adjust this to match your enemy's size
	return Rect2(position - rect_size / 2, rect_size)

func update_giratina_label():
	# If the giratina label doesn't exist or is hidden, we don't need to update it
	if not giratina_label or not giratina_label.is_visible():
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
	
	# If all HPs are zero, display a "Giratina Dead" message
	if all_hp_zero:
		bbcode = "[center][b]Giratina Dead[/b][/center]"
	
	# Set the bbcode text to update the label only if it's still valid and visible
	if giratina_label and giratina_label.is_visible():
		giratina_label.bbcode_text = bbcode

func take_damage(amount, hero_type):
	print("giratina take damage")
	
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
				
		update_giratina_label()

		# Check if all HP types are 0 to trigger death animation
		if pudding_hp == 0 and bomb_hp == 0 and virus_hp == 0 and fries_hp == 0:
			emit_signal("giratina_destroyed", self)  # Ensure signal is emitted
		   # All HPs depleted; start death sequence
			giratina_label.hide()
			giratina_animation.play("death")
		else:
			giratina_animation.play(animation_type)

func giratina_attack():
	giratina_animation.play("attack")
	await giratina_animation.animation_finished

func _on_animation_finished(anim_name):
	if anim_name == "death":
		print("Giratina has died. Removing from scene.")
		# Remove both the giratina and its label
		emit_signal("giratina_destroyed", self)  # Ensure signal is emitted
		queue_free()
