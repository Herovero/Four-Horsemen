extends Node2D

@onready var bgm = $"../bgm"
@onready var giratina_theme = $"../giratina_theme"
@onready var sans_theme = $"../sans_theme"
@onready var background_animation = $"../background/background_animation"
@onready var background_2_animation = $"../background2/background2_animation"
@onready var background_3_animation = $"../background3/background3_animation"
@onready var combo_label = $"../combo_label"
@onready var target_pointer = preload("res://Scenes/target_pointer.tscn").instantiate()  # Adjust the path to your gun pointer scene
@onready var hero_turn: AnimationPlayer = $"../Hero Phase/hero phase"
@onready var enemy_turn: AnimationPlayer = $"../Enemy Phase/enemy phase"
@onready var battle_transaction: AnimationPlayer = $"../Camera2D/battle transaction"
@onready var spinning_slot_poke = $"../Camera2D/spinning slot poke"
@onready var spinning_slot_undertale = $"../Camera2D/spinning slot undertale"
@onready var trump_attack = $TrumpAttack
@onready var xi_attack = $XiAttack
@onready var kim_attack = $KimAttack
@onready var putin_attack = $PutinAttack
@onready var label_pudding_animation = $"../labelPudding/labelPuddingAnimation"
@onready var label_bomb_animation = $"../labelBomb/labelBombAnimation"
@onready var label_virus_animation = $"../labelVirus/labelVirusAnimation"
@onready var label_fries_animation = $"../labelFries/labelFriesAnimation"
@onready var label_pudding: Label = $"../labelPudding"
@onready var label_fries: Label = $"../labelFries"
@onready var label_bomb: Label = $"../labelBomb"
@onready var label_bodyguard: Label = $"../labelBodyguard"
@onready var label_virus: Label = $"../labelVirus"
@onready var swapping = $"../swapping"
@onready var target_pointing: AudioStreamPlayer2D = $"../target pointing"
@onready var target_pointing_2: AudioStreamPlayer2D = $"../target pointing 2"
# Dimensions of the grid in terms of cells
@export var width: int
@export var height: int
# Spacing between grid cells (distance between dots)
@export var offset: int
@export var y_offset: int
# Starting positions of the grid, calculated from the window size.
@onready var x_start = 680
@onready var y_start = 500

var heroes = []  # List of hero nodes
var zombies: Array = []  # List to store zombies
var bats: Array = [] # List to store bats
var ghouls: Array = [] # List to store ghouls
var giratinas: Array = [] # List to store giratinas
var sans: Array = [] # List to store sans
var hero_damage = {}  # To store attack damage for each hero
var is_enemy_active = true
var current_battle_stage = 1
var current_turn: String = "hero" # Turn states: "hero" or "enemy"
var current_target = null  # Track the currently targeted enemy
var bodyguard_hp: int = 4  # Maximum bodyguard HP

@onready var possible_dots = [
	preload("res://Scenes/Dots/blue_dot.tscn"),
	preload("res://Scenes/Dots/green_dot.tscn"),
	preload("res://Scenes/Dots/pink_dot.tscn"),
	preload("res://Scenes/Dots/red_dot.tscn"),
	preload("res://Scenes/Dots/yellow_dot.tscn"),
]

var combo_sounds = [
	preload("res://SFX/combo sound 1.MP3"),
	preload("res://SFX/combo sound 2.MP3"),
	preload("res://SFX/combo sound 3.MP3"),
	preload("res://SFX/combo sound 4.MP3"),
	preload("res://SFX/combo sound 5.MP3"),
]

var combo_count = 0  # Variable to keep track of how many matches are destroyed
var audio_player : AudioStreamPlayer  # Declare an AudioStreamPlayer node
@onready var timer_label = $"../CanvasLayer/Timer_label"
var destroy_timer = Timer.new()
var collapse_timer = Timer.new()
var refill_timer = Timer.new()
var match_timer = Timer.new()
var match_time_limit = 7 # Time limit in seconds
var time_remaining = match_time_limit # Remaining time counter
var match_timer_running = false # To check if the timer is active
var display_score_timer = Timer.new()
var all_dots = []
# Track two dots being swapped by the player
var dot_one = null
var dot_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
# Track the grid positions of the player's initial and final touch during a swipe
var first_touch = Vector2(0,0)
var final_touch = Vector2(0,0)
# Tracks if the player is actively interacting.
var controlling = false
# New mechanic
var matches_being_destroyed = false
var sprite_destroyed_count  ={
	"fries" = 0,
	"bomb" = 0,
	"body_guard" = 4,
	"virus" = 0,
	"pudding" = 0
}

func update_sprite_destroyed_count(current_color):
	var color_map = {
		"blue": "pudding",
		"green": "bomb",
		"pink": "fries",
		"red": "virus",
		"yellow": "body_guard"
	}
	if current_color in color_map:
		sprite_destroyed_count[color_map[current_color]] += 1

func update_labels():
	print("Sprite counts before update:", sprite_destroyed_count)
	label_fries.text = "%d" %sprite_destroyed_count["fries"]
	label_bomb.text = "%d" %sprite_destroyed_count["bomb"]
	label_virus.text = "%d" %sprite_destroyed_count["virus"]
	label_pudding.text = "%d" %sprite_destroyed_count["pudding"]
	label_bodyguard.text = "%d" % min(bodyguard_hp, 4)
	hero_damage["Hero1"] = int(label_pudding.text) if label_pudding.text != "" else 0
	hero_damage["Hero2"] = int(label_bomb.text) if label_bomb.text != "" else 0
	hero_damage["Hero3"] = int(label_virus.text) if label_virus.text != "" else 0
	hero_damage["Hero4"] = int(label_fries.text) if label_fries.text != "" else 0
	
	# Update label text (optional visual update logic)
	print("Hero1 damage: ", hero_damage["Hero1"])
	print("Hero2 damage: ", hero_damage["Hero2"])
	print("Hero3 damage: ", hero_damage["Hero3"])
	print("Hero4 damage: ", hero_damage["Hero4"])
	print("Bodyguard HP: ", bodyguard_hp)

func target_enemy(enemy):
	if current_target == enemy:
		# If the same enemy is clicked again, remove the target
		target_pointer.hide()
		target_pointing_2.play()
		current_target = null
	else:
		# Set the new target and move the gun pointer to it
		current_target = enemy
		target_pointing.play()
		target_pointer.position = enemy.position
		target_pointer.show()

func has_enemies() -> bool:
	return zombies.size() > 0 or bats.size() > 0 or ghouls.size() > 0 or giratinas.size() > 0 or sans.size() > 0

func is_enemy(target) -> bool:
	return target in zombies or target in bats or target in ghouls or target in giratinas or target in sans

func heroes_attack():
	if not has_enemies():
		print("No enemies to attack!")
		return
	
	var hero_names = ["Hero1", "Hero2", "Hero3", "Hero4"]
	
	# Attack the targeted enemy first if it exists
	if current_target and is_enemy(current_target):
		for hero_name in hero_names:
			await attack_hero(hero_name, current_target, 1.0)
	else:
	   # If no target is selected, attack all enemies in sequence
		var all_enemies = zombies + bats + ghouls + giratinas + sans  # Combine all enemies into one list
		# Sort enemies by their x-position (left to right)
		all_enemies.sort_custom(func(a, b): return a.position.x < b.position.x)
		# Calculate the number of enemies
		var num_enemies = all_enemies.size()
		if num_enemies == 0:
			return  # No enemies to attack
		# Calculate the damage multiplier (half damage per enemy)
		var damage_multiplier = 1.0 / num_enemies
		# Have each hero attack all enemies before moving to the next hero
		for hero_name in hero_names:
			var hero_animation_played = false  # Flag to track if animation has played
			for enemy in all_enemies:
				if hero_damage[hero_name] > 0:
					# Only play the hero animation once before attacking any enemies
					if not hero_animation_played:
						match hero_name:
							"Hero1":
								if int(label_pudding.text) == 4:
									putin_attack.play_animation_putin()
									await putin_attack.animation_finished
								elif int(label_pudding.text) >= 5:
									putin_attack.play_animation_putin2()
									await putin_attack.animation_finished
							"Hero2":
								if int(label_bomb.text) == 4:
									kim_attack.play_animation_kim()
									await kim_attack.animation_finished
								elif int(label_bomb.text) >= 5:
									kim_attack.play_animation_kim2()
									await kim_attack.animation_finished
							"Hero3":
								if int(label_virus.text) == 4:
									xi_attack.play_animation_xi()
									await xi_attack.animation_finished
								elif int(label_virus.text) >= 5:
									xi_attack.play_animation_xi2()
									await xi_attack.animation_finished
							"Hero4":
								if int(label_fries.text) == 4:
									trump_attack.play_animation_trump()
									await trump_attack.animation_finished
								elif int(label_fries.text) >= 5:
									trump_attack.play_animation_trump2()
									await trump_attack.animation_finished
						hero_animation_played = true
					
					# Now attack the enemy (without playing the hero animation again)
					var hero_type = ""
					match hero_name:
						"Hero1":
							hero_type = "pudding"
							label_pudding_animation.play("pudding_attack")
						"Hero2":
							hero_type = "bomb"
							label_bomb_animation.play("bomb_attack")
						"Hero3":
							hero_type = "virus"
							label_virus_animation.play("virus_attack")
						"Hero4":
							hero_type = "fries"
							label_fries_animation.play("fries_attack")
					
					# Apply damage to the enemy
					if enemy in zombies:
						enemy.take_damage(hero_damage[hero_name] * damage_multiplier, hero_type)
					elif enemy in bats:
						enemy.take_damage(hero_damage[hero_name] * damage_multiplier, hero_type)
					elif enemy in ghouls:
						enemy.take_damage(hero_damage[hero_name] * damage_multiplier, hero_type)
					elif enemy in giratinas:
						enemy.take_damage(hero_damage[hero_name] * damage_multiplier, hero_type)
					elif enemy in sans:
						enemy.take_damage(hero_damage[hero_name] * damage_multiplier, hero_type)
					
					# Wait for label animation to finish
					var current_label_animation
					match hero_name:
						"Hero1":
							current_label_animation = label_pudding_animation
						"Hero2":
							current_label_animation = label_bomb_animation
						"Hero3":
							current_label_animation = label_virus_animation
						"Hero4":
							current_label_animation = label_fries_animation
					
					await current_label_animation.animation_finished
					
					# Reset animation after it finishes
					match hero_name:
						"Hero1":
							label_pudding_animation.play("RESET")
						"Hero2":
							label_bomb_animation.play("RESET")
						"Hero3":
							label_virus_animation.play("RESET")
						"Hero4":
							label_fries_animation.play("RESET")
	
	reset_labels()

# Individual hero attack with animation
func attack_hero(hero_name: String, target, damage_multiplier: float = 1.0) -> void:
	if hero_name in hero_damage and hero_damage[hero_name] > 0:
		var damage_amount = hero_damage[hero_name] * damage_multiplier
		print("%s attacks dealing %d damage (multiplier: %.2f)" % [hero_name, damage_amount, damage_multiplier])
		
		# Play hero animation first
		match hero_name:
			"Hero1":
				if int(label_pudding.text) == 4:
					putin_attack.play_animation_putin()
					await putin_attack.animation_finished
				elif int(label_pudding.text) >= 5:
					putin_attack.play_animation_putin2()
					await putin_attack.animation_finished
			"Hero2":
				if int(label_bomb.text) == 4:
					kim_attack.play_animation_kim()
					await kim_attack.animation_finished
				elif int(label_bomb.text) >= 5:
					kim_attack.play_animation_kim2()
					await kim_attack.animation_finished
			"Hero3":
				if int(label_virus.text) == 4:
					xi_attack.play_animation_xi()
					await xi_attack.animation_finished
				elif int(label_virus.text) >= 5:
					xi_attack.play_animation_xi2()
					await xi_attack.animation_finished
			"Hero4":
				if int(label_fries.text) == 4:
					trump_attack.play_animation_trump()
					await trump_attack.animation_finished
				elif int(label_fries.text) >= 5:
					trump_attack.play_animation_trump2()
					await trump_attack.animation_finished
		
		# Attack the target
		if target in zombies:
			var hero_type = ""
			match hero_name:
				"Hero1":
					hero_type = "pudding"
					label_pudding_animation.play("pudding_attack")
				"Hero2":
					hero_type = "bomb"
					label_bomb_animation.play("bomb_attack")
				"Hero3":
					hero_type = "virus"
					label_virus_animation.play("virus_attack")
				"Hero4":
					hero_type = "fries"
					label_fries_animation.play("fries_attack")
			
			target.take_damage(damage_amount, hero_type)
		elif target in bats:
			var hero_type = ""
			match hero_name:
				"Hero1":
					hero_type = "pudding"
					label_pudding_animation.play("pudding_attack")
				"Hero2":
					hero_type = "bomb"
					label_bomb_animation.play("bomb_attack")
				"Hero3":
					hero_type = "virus"
					label_virus_animation.play("virus_attack")
				"Hero4":
					hero_type = "fries"
					label_fries_animation.play("fries_attack")
			
			target.take_damage(damage_amount, hero_type)
		elif target in ghouls:
			var hero_type = ""
			match hero_name:
				"Hero1":
					hero_type = "pudding"
					label_pudding_animation.play("pudding_attack")
				"Hero2":
					hero_type = "bomb"
					label_bomb_animation.play("bomb_attack")
				"Hero3":
					hero_type = "virus"
					label_virus_animation.play("virus_attack")
				"Hero4":
					hero_type = "fries"
					label_fries_animation.play("fries_attack")
			
			target.take_damage(damage_amount, hero_type)
		elif target in giratinas:
			var hero_type = ""
			match hero_name:
				"Hero1":
					hero_type = "pudding"
					label_pudding_animation.play("pudding_attack")
				"Hero2":
					hero_type = "bomb"
					label_bomb_animation.play("bomb_attack")
				"Hero3":
					hero_type = "virus"
					label_virus_animation.play("virus_attack")
				"Hero4":
					hero_type = "fries"
					label_fries_animation.play("fries_attack")
			
			target.take_damage(damage_amount, hero_type)
		elif target in sans:
			var hero_type = ""
			match hero_name:
				"Hero1":
					hero_type = "pudding"
					label_pudding_animation.play("pudding_attack")
				"Hero2":
					hero_type = "bomb"
					label_bomb_animation.play("bomb_attack")
				"Hero3":
					hero_type = "virus"
					label_virus_animation.play("virus_attack")
				"Hero4":
					hero_type = "fries"
					label_fries_animation.play("fries_attack")
			
			target.take_damage(damage_amount, hero_type)
		
		# Wait for both animations to finish
		var current_label_animation
		match hero_name:
			"Hero1":
				current_label_animation = label_pudding_animation
			"Hero2":
				current_label_animation = label_bomb_animation
			"Hero3":
				current_label_animation = label_virus_animation
			"Hero4":
				current_label_animation = label_fries_animation
		
		await current_label_animation.animation_finished
		
		# Reset animation after it finishes
		match hero_name:
			"Hero1":
				label_pudding_animation.play("RESET")
			"Hero2":
				label_bomb_animation.play("RESET")
			"Hero3":
				label_virus_animation.play("RESET")
			"Hero4":
				label_fries_animation.play("RESET")

# Reset hero labels after attacks
func reset_labels() -> void:
	print("labels reset")
	# Reset the sprite_destroyed_count dictionary
	for key in sprite_destroyed_count.keys():
		#if key != "body_guard":  # Skip resetting "bodyguard"
		sprite_destroyed_count[key] = 0

	# Reset labels
	label_pudding.text = "0"
	label_bomb.text = "0"
	label_virus.text = "0"
	label_fries.text = "0"

	# Reset hero_damage values
	hero_damage["Hero1"] = 0
	hero_damage["Hero2"] = 0
	hero_damage["Hero3"] = 0
	hero_damage["Hero4"] = 0
	
	label_fries.text = "%d" %sprite_destroyed_count["fries"]
	label_bomb.text = "%d" %sprite_destroyed_count["bomb"]
	label_virus.text = "%d" %sprite_destroyed_count["virus"]
	label_pudding.text = "%d" %sprite_destroyed_count["pudding"]
	
	print("All hero labels and damage value reset.")
	
	target_pointer.hide()
	current_target = null
	
	# Only switch turn if enemies are still active
	if is_enemy_active:
		switch_turn()

var phase_switching = false  # Flag to indicate if phase switching is in progress

func switch_turn():
	if phase_switching:
		return  # Prevent switching while already switching phases
	
	phase_switching = true  # Set the flag to indicate phase switching is in progress
	
	if current_turn == "hero":
		current_turn = "zombie"
		enemy_phase()
	else:
		current_turn = "hero"
		hero_phase()
	
	# After the phase switch completes, reset the flag
	phase_switching = false

# Function to handle the battle_transaction animation_finished signal
func _on_battle_transaction_finished(_anim_name):
	play_appear_animations(zombies, "zombie_appear")
	play_appear_animations(bats, "bat_appear")
	play_appear_animations(ghouls, "ghoul_appear")
	play_appear_animations(giratinas, "giratina_appear")
	play_appear_animations(sans, "sans_appear")

func play_appear_animations(enemies: Array, method_name: String):
	for enemy in enemies:
		if enemy.has_method(method_name):
			enemy.call(method_name)

func _on_battle02_transaction_finished(_anim_name):
	if current_battle_stage == 2:
		print("Battle02 transaction completed. Spawning new enemies.")
		spawn_battle_enemies(2)
		current_turn = "hero"
		can_touch_input = true
		print("Battle02 started. Hero Phase activated.")

func _on_battle03_transaction_finished(_anim_name):
	if current_battle_stage == 3:
		print("Battle03 transaction completed. Spawning new enemies.")
		spawn_battle_enemies(3)
		current_turn = "hero"
		can_touch_input = true
		print("Battle03 started. Hero Phase activated.")

func _on_battle04_transaction_finished(_anim_name):
	if current_battle_stage == 4:
		print("Battle04 transaction completed. Spawning new enemies.")
		spawn_battle_enemies(4)
		current_turn = "hero"
		can_touch_input = true
		print("Battle04 started. Hero Phase activated.")

func _on_battle05_transaction_finished(_anim_name):
	if current_battle_stage == 5:
		print("Battle05 transaction completed. Spawning new enemies.")
		spawn_battle_enemies(5)
		current_turn = "hero"
		can_touch_input = true
		print("Battle05 started. Hero Phase activated.")

func _on_spinning_slot_giratina_finished():
	print("Boss fight intro animation finished. Starting boss fight.")
	spawn_battle_enemies(5)  # Spawn enemies for the boss fight
	current_turn = "hero"
	await get_tree().create_timer(2.5).timeout
	can_touch_input = true
	giratina_theme.play()
	print("Boss fight started. Hero Phase activated.")

func _on_spinning_slot_sans_finished():
	print("Boss fight intro animation finished. Starting boss fight.")
	spawn_battle_enemies(5)  # Spawn enemies for the boss fight
	current_turn = "hero"
	await get_tree().create_timer(15).timeout
	background_3_animation.play("RESET")
	await get_tree().create_timer(1).timeout
	can_touch_input = true
	sans_theme.play()
	print("Boss fight started. Hero Phase activated.")

func spawn_battle_enemies(stage: int):
	print("Spawning Battle%02d Enemies" % stage)
	match stage:
		2:
			var _enemy1 = spawn_bat(Vector2(200, 300))
			#var _enemy2 = spawn_bat(Vector2(400, 300))
		3:
			var _enemy1 = spawn_ghoul(Vector2(200, 300))
			#var _enemy2 = spawn_ghoul(Vector2(400, 300))
		4:
			var _enemy1 = spawn_zombie(Vector2(100, 300))
			var _enemy2 = spawn_ghoul(Vector2(300, 300))
			var _enemy3 = spawn_bat(Vector2(500, 300))
		5:
			#var _enemy1 = spawn_giratina(Vector2(300, 200))
			var _enemy1 = spawn_sans(Vector2(300, 300))
	
	is_enemy_active = true
	play_appear_animations(zombies, "zombie_appear")
	play_appear_animations(bats, "bat_appear")
	play_appear_animations(ghouls, "ghoul_appear")
	play_appear_animations(giratinas, "giratina_appear")
	play_appear_animations(sans, "sans_appear")

func check_battle_stage_transition():
	if zombies.size() == 0 and bats.size() == 0 and ghouls.size() == 0 and giratinas.size() == 0 and sans.size() == 0:
		is_enemy_active = false
		await get_tree().create_timer(1.5).timeout
		transition_to_next_battle_stage()

func transition_to_next_battle_stage():
	var next_stage = current_battle_stage + 1
	if next_stage > 5:
		return  # No more stages beyond 5
	
	print("Battle%02d completed. Preparing for Battle%02d." % [current_battle_stage, next_stage])
	current_battle_stage = next_stage
	
	if battle_transaction:
		if next_stage == 5:
			# Play the boss fight intro animation for battle05
			bgm.stop()
			background_animation.play("darken")
			await get_tree().create_timer(1.5).timeout
			#spinning_slot_poke.play()
			spinning_slot_undertale.play()
			await get_tree().create_timer(5.5).timeout
			#background_2_animation.play("lighten")
			background_3_animation.play("lighten")
			await get_tree().create_timer(1).timeout
			#_on_spinning_slot_giratina_finished()
			_on_spinning_slot_sans_finished()
		else:
			# Play the regular battle transaction animation for other stages
			var animation_name = "battle%02d_transaction" % next_stage
			var callback_name = "_on_battle%02d_transaction_finished" % next_stage
			battle_transaction.play(animation_name)
			battle_transaction.connect("animation_finished", Callable(self, callback_name))

func hero_phase():
	print("Hero Phase!")
	# Reset or prepare for hero actions here
	hero_turn.play_animation_herophase()

func _on_hero_phase_animation_finished(_anim_name):
	print("can touch input")
	can_touch_input = true

func enemy_phase():
	print("Enemy Phase!")
	
	# Play the enemy phase animation
	enemy_turn.play_animation_enemyphase()

func _on_enemy_phase_animation_finished(_anim_name: String):
	print("Enemy phase animation finished. Processing attacks.")
	
	# Combine all enemies into a single list
	var all_enemies = zombies + bats + ghouls + giratinas + sans
	
	# Sort enemies by their x-position (left to right)
	all_enemies.sort_custom(func(a, b): return a.position.x < b.position.x)
	
	# Process each enemy's attack sequentially
	for i in range(all_enemies.size()):
		var enemy = all_enemies[i]
		if bodyguard_hp > 0:
			bodyguard_hp -= 1
			label_bodyguard.text = str(bodyguard_hp)
			print("%s attacked! Bodyguard HP: %d" % [enemy.name, bodyguard_hp])
			
			# Call the enemy's attack animation
			if enemy.has_method("zombie_attack"):
				print("Starting zombie attack animation.")
				enemy.zombie_attack()  # Trigger attack animation
				await enemy.get_node("zombie_animation").animation_finished  # Wait for the animation to finish
				print("Zombie attack animation finished.")
			elif enemy.has_method("bat_attack"):
				print("Starting bat attack animation.")
				enemy.bat_attack()  # Trigger attack animation
				await enemy.get_node("bat_animation").animation_finished  # Wait for the animation to finish
				print("Bat attack animation finished.")
			elif enemy.has_method("ghoul_attack"):
				print("Starting ghoul attack animation.")
				enemy.ghoul_attack()  # Trigger attack animation
				await enemy.get_node("ghoul_animation").animation_finished  # Wait for the animation to finish
				print("Ghoul attack animation finished.")
			elif enemy.has_method("giratina_attack"):
				print("Starting giratina attack animation.")
				enemy.giratina_attack()  # Trigger attack animation
				await enemy.get_node("giratina_animation").animation_finished  # Wait for the animation to finish
				print("Giratina attack animation finished.")
			elif enemy.has_method("sans_attack"):
				print("Starting sans attack animation.")
				enemy.sans_attack()  # Trigger attack animation
				await enemy.get_node("sans_animation").animation_finished  # Wait for the animation to finish
				print("Sans attack animation finished.")
		else:
			print("Game Over!")
			return  # Exit if the game is over
			
	switch_turn()

# Function to spawn zombies
func spawn_zombie(zombie_position: Vector2):
	var zombie_scene = preload("res://Sprites/zombie.tscn")  # Adjust path
	var zombie_instance = zombie_scene.instantiate()
	if zombie_instance:
		print("Zombie spawned with HP: ", zombie_instance)
		add_child(zombie_instance)
		zombie_instance.position = zombie_position
		zombies.append(zombie_instance)
		
		# Connect the zombie_destroyed signal to the handler
		zombie_instance.connect("zombie_destroyed", Callable(self, "_on_zombie_destroyed"))
	else:
		print("Zombie instantiation failed.")

func spawn_bat(bat_position: Vector2):
	var bat_scene = preload("res://Scenes/bat.tscn")  # Adjust path
	var bat_instance = bat_scene.instantiate()
	if bat_instance:
		print("Bat spawned with HP: ", bat_instance)
		add_child(bat_instance)
		bat_instance.position = bat_position
		bats.append(bat_instance)
		
		# Connect the bat_destroyed signal to the handler
		bat_instance.connect("bat_destroyed", Callable(self, "_on_bat_destroyed"))
	else:
		print("Bat instantiation failed.")

func spawn_ghoul(ghoul_position: Vector2):
	var ghoul_scene = preload("res://Scenes/ghoul.tscn")  # Adjust path
	var ghoul_instance = ghoul_scene.instantiate()
	if ghoul_instance:
		print("Ghoul spawned with HP: ", ghoul_instance)
		add_child(ghoul_instance)
		ghoul_instance.position = ghoul_position
		ghouls.append(ghoul_instance)
		
		# Connect the ghoul_destroyed signal to the handler
		ghoul_instance.connect("ghoul_destroyed", Callable(self, "_on_ghoul_destroyed"))
	else:
		print("Ghoul instantiation failed.")

func spawn_giratina(giratina_position: Vector2):
	var giratina_scene = preload("res://Scenes/giratina.tscn")  # Adjust path
	var giratina_instance = giratina_scene.instantiate()
	if giratina_instance:
		print("Giratina spawned with HP: ", giratina_instance)
		add_child(giratina_instance)
		giratina_instance.position = giratina_position
		giratinas.append(giratina_instance)
		
		# Connect the giratina_destroyed signal to the handler
		giratina_instance.connect("giratina_destroyed", Callable(self, "_on_giratina_destroyed"))
	else:
		print("Giratina instantiation failed.")

func spawn_sans(sans_position: Vector2):
	var sans_scene = preload("res://Scenes/sans.tscn")  # Adjust path
	var sans_instance = sans_scene.instantiate()
	if sans_instance:
		print("Sans spawned with HP: ", sans_instance)
		add_child(sans_instance)
		sans_instance.position = sans_position
		sans.append(sans_instance)
		
		# Connect the sans_destroyed signal to the handler
		sans_instance.connect("sans_destroyed", Callable(self, "_on_sans_destroyed"))
	else:
		print("Sans instantiation failed.")
	
# Damage the zombie
func damage_zombie(zombie_instance, damage_amount, hero_type):
	print("Trying to damage zombie")
	if zombie_instance:
		print("Zombie instance is valid. Applying damage:", damage_amount)
		zombie_instance.take_damage(damage_amount, hero_type)
	else:
		print("Zombie instance is invalid!")

func damage_bat(bat_instance, damage_amount, hero_type):
	print("Trying to damage bat")
	if bat_instance:
		print("Bat instance is valid. Applying damage:", damage_amount)
		bat_instance.take_damage(damage_amount, hero_type)
	else:
		print("Bat instance is invalid!")

func damage_ghoul(ghoul_instance, damage_amount, hero_type):
	print("Trying to damage ghoul")
	if ghoul_instance:
		print("Ghoul instance is valid. Applying damage:", damage_amount)
		ghoul_instance.take_damage(damage_amount, hero_type)
	else:
		print("Ghoul instance is invalid!")

func damage_giratina(giratina_instance, damage_amount, hero_type):
	print("Trying to damage giratina")
	if giratina_instance:
		print("Giratina instance is valid. Applying damage:", damage_amount)
		giratina_instance.take_damage(damage_amount, hero_type)
	else:
		print("Giratina instance is invalid!")

func damage_sans(sans_instance, damage_amount, hero_type):
	print("Trying to damage sans")
	if sans_instance:
		print("Sans instance is valid. Applying damage:", damage_amount)
		sans_instance.take_damage(damage_amount, hero_type)
	else:
		print("Sans instance is invalid!")
		
# Handle attack stop for remaining heroes when enemy dies
func _on_zombie_destroyed(zombie_instance):
	if zombie_instance in zombies:
		zombies.erase(zombie_instance)  # Remove the zombie from the list
		print("Zombie destroyed and removed from the list.")
		
		# Check if all enemies are dead
		check_battle_stage_transition()

func _on_bat_destroyed(bat_instance):
	if bat_instance in bats:
		bats.erase(bat_instance)  # Remove the bat from the list
		print("Bat destroyed and removed from the list.")
		
		# Check if all enemies are dead
		check_battle_stage_transition()

func _on_ghoul_destroyed(ghoul_instance):
	if ghoul_instance in ghouls:
		ghouls.erase(ghoul_instance)  # Remove the ghoul from the list
		print("Ghoul destroyed and removed from the list.")
		
		# Check if all enemies are dead
		check_battle_stage_transition()

func _on_giratina_destroyed(giratina_instance):
	if giratina_instance in giratinas:
		giratinas.erase(giratina_instance)  # Remove the giratina from the list
		print("Giratina destroyed and removed from the list.")
		
		# Check if all enemies are dead
		check_battle_stage_transition()

func _on_sans_destroyed(sans_instance):
	if sans_instance in sans:
		sans.erase(sans_instance)  # Remove the sans from the list
		print("Sans destroyed and removed from the list.")
		
		# Check if all enemies are dead
		check_battle_stage_transition()


var destroyed_count = 0
var label_display


func _ready() -> void:
	# Debug grid position
	print("x_start: ", x_start)
	print("y_start: ", y_start)

	setup_timers() # Connects timers to their respective callback functions and sets wait times
	# Ensure display_score_timer is added to the scene tree
	if display_score_timer.get_parent() == null:
		add_child(display_score_timer)
	display_score_timer.start()
	randomize()
	all_dots = make_2d_array() # Initializes the all_dots 2D array with null values
	spawn_dots() # Spawns dots into the grid.
	randomize()
	
	# Initialize match timer
	if match_timer.get_parent() == null:
		add_child(match_timer)
	match_timer.connect("timeout", Callable(self, "on_match_timer_timeout"))
	match_timer.set_one_shot(true)
	timer_label.text = ""
	
	# Ensure an AudioStreamPlayer node is present
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)  # Add the player to the scene if not already added
	
	label_bodyguard.text = str(bodyguard_hp)
	
	# Add the gun pointer to the scene
	add_child(target_pointer)
	target_pointer.hide()  # Initially hide the gun pointer
	
	# Connect the battle_transaction animation_finished signal
	if battle_transaction:
		battle_transaction.connect("animation_finished", Callable(self, "_on_battle_transaction_finished"))
	
	# Connect the hero and enemy phase animation_finished signals
	if hero_turn:
		hero_turn.connect("animation_finished", Callable(self, "_on_hero_phase_animation_finished"))
	if enemy_turn:
		enemy_turn.connect("animation_finished", Callable(self, "_on_enemy_phase_animation_finished"))
	
	# Spawn enemies
	var _enemy1 = spawn_zombie(Vector2(200, 300))
	var _enemy2 = spawn_zombie(Vector2(400, 300))
	
	if zombies.size() > 0:
		damage_zombie(zombies[0], 0, "pudding")
		damage_zombie(zombies[0], 0, "bomb")
		damage_zombie(zombies[0], 0, "virus")
		damage_zombie(zombies[0], 0, "fries")
	
	if bats.size() > 0:
		damage_bat(bats[0], 0, "pudding")
		damage_bat(bats[0], 0, "bomb")
		damage_bat(bats[0], 0, "virus")
		damage_bat(bats[0], 0, "fries")
	
	if ghouls.size() > 0:
		damage_ghoul(ghouls[0], 0, "pudding")
		damage_ghoul(ghouls[0], 0, "bomb")
		damage_ghoul(ghouls[0], 0, "virus")
		damage_ghoul(ghouls[0], 0, "fries")
	
	if giratinas.size() > 0:
		damage_giratina(giratinas[0], 0, "pudding")
		damage_giratina(giratinas[0], 0, "bomb")
		damage_giratina(giratinas[0], 0, "virus")
		damage_giratina(giratinas[0], 0, "fries")
	
	if sans.size() > 0:
		damage_sans(sans[0], 0, "pudding")
		damage_sans(sans[0], 0, "bomb")
		damage_sans(sans[0], 0, "virus")
		damage_sans(sans[0], 0, "fries")
	
func setup_timers():
	# Manage delays between destroying matches, collapsing columns, and refilling the grid
	
	# Ensure destroy_timer is added to the scene tree
	if destroy_timer.get_parent() == null:
		add_child(destroy_timer)
	destroy_timer.connect("timeout", Callable(self, "destroy_matches"))
	destroy_timer.set_one_shot(true)
	destroy_timer.set_wait_time(0.2)
	
	# Ensure collapse_timer is added to the scene tree
	if collapse_timer.get_parent() == null:
		add_child(collapse_timer)
	collapse_timer.connect("timeout", Callable(self, "collapse_columns"))
	collapse_timer.set_one_shot(true)
	collapse_timer.set_wait_time(0.2)
	
	# Ensure refill_timer is added to the scene tree
	if refill_timer.get_parent() == null:
		add_child(refill_timer)
	refill_timer.connect("timeout", Callable(self, "refill_columns"))
	refill_timer.set_one_shot(true)
	refill_timer.set_wait_time(0.2)

func start_match_timer():
	time_remaining = match_time_limit
	match_timer.set_wait_time(time_remaining)
	match_timer.start()
	match_timer_running = true
	
func stop_match_timer():
	if match_timer.is_stopped():
		return
	match_timer.stop()
	timer_label.text = ""
	
	# Ensure the signal is not already connected
	if not display_score_timer.is_connected("timeout", Callable(self, "display_score")):
		display_score_timer.connect("timeout", Callable(self, "display_score"))
	display_score_timer.stop()
	display_score_timer.set_one_shot(true)
	display_score_timer.set_wait_time(1.0)
	
func is_in_array(array, item):
	for i in array.size():
		if array[i] == item:
			return true
	return false

# Initializes the all_dots 2D array with null values
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func spawn_dots():
	for i in width:
		for j in height:
			# Randomly selects a dot from possible_dots and places it in the grid
			var rand = floor(randf_range(0, possible_dots.size()))
			var dot = possible_dots[rand].instantiate()
			var loops = 0
			# Avoids immediate matches by checking match_at() during dot placement.
			# Checks if placing a dot at (i, j) results in a match (3+ dots of the same color in a row or column)
			while (match_at(i, j, dot.color) && loops < 100):
				rand = floor(randf_range(0,possible_dots.size()))
				loops += 1
				dot = possible_dots[rand].instantiate()
			add_child(dot)
			dot.position = grid_to_pixel(i, j)
			all_dots[i][j] = dot
			
			
func match_at(i, j, target_color):
	if i > 1:
		if all_dots[i - 1][j] != null && all_dots[i - 2][j] != null:
			if all_dots[i - 1][j].color == target_color && all_dots[i - 2][j].color == target_color:
				return true
	if j > 1:
		if all_dots[i][j - 1] != null && all_dots[i][j - 2] != null:
			if all_dots[i][j - 1].color == target_color && all_dots[i][j - 2].color == target_color:
				return true
	pass

# Convert between grid coordinates and pixel coordinates for dot placement and movement
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x,pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)

# Checks if a position is within the grid bounds
func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < width:
		if grid_position.y >= 0 && grid_position.y < height:
			return true
	return false

var can_touch_input = true  # Controls whether touch input is allowed

func touch_input():
	if Input.is_action_just_pressed("ui_touch") and can_touch_input:
		combo_label.text = ""
		combo_count = 0
		
		# If a touch begins (ui_touch pressed), records the grid position
		var touch_pos = get_global_mouse_position()
		
		# Check if an enemy is clicked
		for zombie in zombies:
			if zombie.get_rect().has_point(touch_pos):
				target_enemy(zombie)
				return
		
		for bat in bats:
			if bat.get_rect().has_point(touch_pos):
				target_enemy(bat)
				return
		
		for ghoul in ghouls:
			if ghoul.get_rect().has_point(touch_pos):
				target_enemy(ghoul)
				return
		
		for giratina in giratinas:
			if giratina.get_rect().has_point(touch_pos):
				target_enemy(giratina)
				return
		
		for sans in sans:
			if sans.get_rect().has_point(touch_pos):
				target_enemy(sans)
				return
		
		# If no enemy is clicked, proceed with normal touch input
		if is_in_grid(pixel_to_grid(touch_pos.x,touch_pos.y)):
			first_touch = pixel_to_grid(touch_pos.x, touch_pos.y)
			dot_one = all_dots[first_touch.x][first_touch.y]
			if dot_one:
				controlling = true
				start_match_timer()
	
	elif Input.is_action_pressed("ui_touch") and controlling:
		# Continuously track touch position
		var current_touch = get_global_mouse_position()
		var current_grid = pixel_to_grid(current_touch.x, current_touch.y)
		if is_in_grid(current_grid) and current_grid != first_touch:
			# If the touch moves to a new grid cell, swap dots
			var direction = current_grid - first_touch
			if abs(direction.x) + abs(direction.y) == 1:  # Ensure only orthogonal swaps
				swap_dots(first_touch.x, first_touch.y, direction)
				first_touch = current_grid  # Update the current grid position
		
	elif Input.is_action_just_released("ui_touch"):
		controlling = false
		stop_match_timer()
		dot_one = null
		dot_two = null
			
func swap_dots(column, row, direction):
	var first_dot = all_dots[column][row]
	var other_dot = all_dots[column + direction.x][row + direction.y]
	
	if first_dot and other_dot:
		# Upgrade grid positions
		all_dots[column][row] = other_dot
		all_dots[column + direction.x][row + direction.y] = first_dot
		
		# Swap positions visually
		first_dot.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_dot.move(grid_to_pixel(column, row))
		swapping.play()
		
func store_info(first_dot, other_dot, place, direciton):
	dot_one = first_dot
	dot_two = other_dot
	last_place = place
	last_direction = direciton
	pass
	
func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_dots(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_dots(grid_1.x, grid_1.y, Vector2(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_dots(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_dots(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	touch_input()
	
	# Run match detection after the player finishes their turn
	if !controlling:
		find_matches()
	
	if match_timer_running:
		time_remaining -= delta
		if time_remaining > 0 and Input.is_action_pressed("ui_touch"):
			# Update the label text
			timer_label.text = "Time remaining: %d" % int(time_remaining)
		else:
			# Timer expired
			match_timer_running = false
			time_remaining = 0
			timer_label.text = ""
			on_match_timer_timeout()
		
	
func find_matches():
	if matches_being_destroyed:
		return
	
	var found_match = false

	for i in width:
		for j in height:
			if all_dots[i][j] != null:
				var current_color = all_dots[i][j].color
				if i > 0 and i < width -1:
					if !is_piece_null(i - 1, j) and !is_piece_null(i + 1, j):
						if all_dots[i - 1][j].color == current_color and all_dots[i + 1][j].color == current_color:
							match_and_dim(all_dots[i - 1][j])
							match_and_dim(all_dots[i][j])
							match_and_dim(all_dots[i + 1][j])
							found_match = true

				if j > 0 and j < height -1:
					if !is_piece_null(i, j - 1) and !is_piece_null(i, j + 1):
						if all_dots[i][j - 1].color == current_color and all_dots[i][j + 1].color == current_color:
							match_and_dim(all_dots[i][j - 1])
							match_and_dim(all_dots[i][j])
							match_and_dim(all_dots[i][j + 1])
							found_match = true

	if found_match:
		matches_being_destroyed = true # Prevent further matches from being found
		destroy_timer.start()

		destroyed_count = 0 #reset the count to zero

func is_piece_null(column, row):
	if all_dots[column][row] == null:
		return true
	return false

func match_and_dim(item):
	can_touch_input = false  # Disable touch input
	item.matched = true
	item.dim()
	
var color

func destroy_matches():
	can_touch_input = false  # Disable touch input
	var was_matched = false
	destroyed_count = 0

	var matches_to_destroy = []  # Store the matched groups
	var visited = []  # To track visited dots so they are not part of multiple groups

	# Collect all the matched groups
	for i in range(width):
		for j in range(height):
			if all_dots[i][j] != null and all_dots[i][j].matched and not is_visited(i, j, visited):
				var group = get_matched_group(i, j, visited)  # Get the group of matched dots
				if group:
					matches_to_destroy.append(group)
					for dot in group:
						dot.matched = false  # Reset matched status

	if matches_to_destroy.size() > 0:
		was_matched = true

	# Destroy the groups one by one
	var first_match = true  # Flag to track the first match

	for group in matches_to_destroy:
		# Trigger combo count, sound, and label updates immediately
		combo_count += 1
		update_combo_label()
		play_combo_sound(combo_count)
		
		if not first_match:
			pass
		else:
			first_match = false  # After the first match, disable the first match condition

		# Play animations for all dots in the group simultaneously
		for dot in group:
			update_sprite_destroyed_count(dot.color)  # Update count for destroyed color
			
			# Check if the count reaches the threshold of 4 and trigger animations
			var color_map = {
				"blue": "pudding",
				"green": "bomb",
				"pink": "fries",
				"red": "virus",
				"yellow": "body_guard"
			}
			# Trigger special animations under certain requirements
			#if dot.color in color_map and sprite_destroyed_count[color_map[dot.color]] == 4:
				#number_of_destroy(dot.color)
			#elif dot.color in color_map and sprite_destroyed_count[color_map[dot.color]] >= 5:
				#number_of_destroy2(dot.color)
			
			# Play animation for the current dot
			var anim_player = dot.get_node_or_null("AnimationPlayer")
			if anim_player:
				anim_player.play("disappear")
			
			# Update the bodyguard HP if a bodyguard dot is destroyed
			if dot.color == "yellow":
				# Make sure bodyguard HP does not exceed 4
				if sprite_destroyed_count["body_guard"] < 4:
					sprite_destroyed_count["body_guard"] += 1
				bodyguard_hp = min(sprite_destroyed_count["body_guard"], 4)
				label_bodyguard.text = "Bodyguard HP: %d" % bodyguard_hp
		
		update_labels()  # Update any other labels, such as score or time
		
		# Wait for the animation to finish for the entire group
		var max_animation_time = 0.5  # Adjust this to match the duration of your "disappear" animation
		await get_tree().create_timer(max_animation_time).timeout
		# After the animation, queue_free the dot
		for dot in group:
			if dot != null:
				destroyed_count += 1
				dot.queue_free()  # Destroy the dot
		
		# Check if collapse should happen now
		if !matches_being_destroyed:
			collapse_timer.start()  # Make sure the collapse timer is started
			break  # Avoid further operations until collapse is triggered

	# If any matches were destroyed, start the column collapse and refill processes
	if was_matched:
		collapse_columns()  # Start collapsing columns after matches are destroyed
		collapse_timer.start()

	matches_being_destroyed = false

# Function to play combo sound based on combo count
func play_combo_sound(count: int):
	if count <= combo_sounds.size():
		# Set the stream of the player to the corresponding combo sound
		audio_player.stream = combo_sounds[count - 1]
		audio_player.play()  # Play the sound
	else:
		# Play the last sound if the combo count exceeds available sounds
		audio_player.stream = combo_sounds[combo_sounds.size() - 1]
		audio_player.play()

# Function to update the combo label
func update_combo_label():
	combo_label.text = "COMBO %d" % combo_count

# This function gets the matched group of dots starting from the given coordinates
# It also marks the visited dots to ensure that they are not counted in multiple groups
func get_matched_group(x, y, visited):
	var group = []
	if all_dots[x][y] != null and all_dots[x][y].matched and not is_visited(x, y, visited):
		var dot_color = all_dots[x][y].color  # Get the color of the starting dot
		flood_fill_group(x, y, group, visited, dot_color)  # Fill the group with connected dots of the same color
	return group


# This function uses flood fill to collect all the connected matched dots of the same color in the group
# It marks dots as visited so they don't appear in another group
func flood_fill_group(x, y, group, visited, dot_color):
	var stack = [Vector2(x, y)]  # Use Vector2 to store the coordinates
	while stack.size() > 0:
		var pos = stack.pop_back()
		var ix = pos.x
		var iy = pos.y
		if all_dots[ix][iy] != null and all_dots[ix][iy].matched and not is_visited(ix, iy, visited):
			if all_dots[ix][iy].color == dot_color:  # Only add dots of the same color
				group.append(all_dots[ix][iy])
				visited.append(Vector2(ix, iy))  # Mark this dot as visited
				# Check adjacent dots
				if ix + 1 < width and all_dots[ix + 1][iy] != null and all_dots[ix + 1][iy].matched:
					stack.append(Vector2(ix + 1, iy))
				if ix - 1 >= 0 and all_dots[ix - 1][iy] != null and all_dots[ix - 1][iy].matched:
					stack.append(Vector2(ix - 1, iy))
				if iy + 1 < height and all_dots[ix][iy + 1] != null and all_dots[ix][iy + 1].matched:
					stack.append(Vector2(ix, iy + 1))
				if iy - 1 >= 0 and all_dots[ix][iy - 1] != null and all_dots[ix][iy - 1].matched:
					stack.append(Vector2(ix, iy - 1))


# Helper function to check if a dot has already been visited in a group
func is_visited(x, y, visited):
	return visited.has(Vector2(x, y))

					
func collapse_columns():
	can_touch_input = false  # Disable touch input
	await get_tree().create_timer(0.3).timeout
	for i in width:
		for j in height:
			if all_dots[i][j] == null:
				for k in range(j + 1, height):
					if all_dots[i][k] != null:
						all_dots[i][k].move(grid_to_pixel(i, j))
						all_dots[i][j] = all_dots[i][k]
						all_dots[i][k] = null
						break
	refill_timer.start()


func refill_columns():
	can_touch_input = false  # Disable touch input
	for i in width:
		for j in height:
			if all_dots[i][j] == null:
				var rand = floor(randf_range(0, possible_dots.size()))
				var dot = possible_dots[rand].instantiate()
				var loops = 0
				
				while (match_at(i, j, dot.color) && loops < 100): # Prevent infinite loops
					rand = floor(randf_range(0, possible_dots.size()))
					loops += 1
					dot = possible_dots[rand].instantiate()
					
				add_child(dot)
				dot.position = grid_to_pixel(i, j)
				all_dots[i][j] = dot
	after_refill()

# Check if the grid stops collapsing and matching
func after_refill():
	for i in width:
		for j in height:
			if all_dots[i][j] != null:
				if match_at(i, j, all_dots[i][j].color):
					find_matches()
					destroy_timer.start()
					return
	heroes_attack()

func on_match_timer_timeout():
	controlling = false

func number_of_destroy(target_color):
	print("Destroyed color:", target_color)
	if target_color == "blue":
		putin_attack.play_animation_putin()
	
	if target_color == "green":
		kim_attack.play_animation_kim()
		
	if target_color == "red" :
		xi_attack.play_animation_xi()
		
	if target_color == "pink" :
		trump_attack.play_animation_trump()

func number_of_destroy2(target_color):
	if target_color == "red" :
		xi_attack.play_animation_xi2()
		
	if target_color == "pink" :
		trump_attack.play_animation_trump2()
