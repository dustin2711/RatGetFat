extends AnimatedSprite2D

class_name Rat

@export var is_computer = true
@export var can_become_player = false

@export var key_up = KEY_W
@export var key_down = KEY_S
@export var key_right = KEY_D
@export var key_left = KEY_A
@export var key_eat = KEY_SPACE
@export var key_drop = KEY_SHIFT

@export var player_name: String = "SP1"
@export var player_color: Color = Color.RED
@export var speed = 200  # Adjust this value to control the movement speed.
@export var stunned_ms = 1000
@export var eating_ms = 1200 
@export var invulnerable_ms = 300  # Make invulerable after picking up food
@export var progress_bar: ColorizedProgressBar = null

@onready var root = get_parent()
@onready var winner_label: Label = root.find_child("Camera").find_child("Canvas").find_child("WinnerLabel")
@onready var restart_label: Label = root.find_child("Camera").find_child("Canvas").find_child("RestartLabel")
@onready var food_spawner = root.find_child("FoodSpawner")
@onready var audio_eating: AudioStreamPlayer2D = $AudioEating
@onready var audio_squeaking: AudioStreamPlayer2D = $AudioSqueaking
@onready var stun_sprite: AnimatedSprite2D = $Stun
@onready var name_label: Label = $Name

# When this is != null, then currently food is eaten
var time_started_eating = null
var time_being_stunned = null
var time_of_pickup = null

var food: Food = null
var target_food: Food = null
var best_food: Food = null # computer only

var last_velocity = Vector2(0, 0)

var time_of_calling_ready = 0

func lighten_color(color: Color, factor: float) -> Color:
	""" 0 means no change, 1 means fully lighten. """
	factor = clamp(factor, 0.0, 1.0)
	# Calculate the new color components by increasing them
	return Color(color.r + (1.0 - color.r) * factor,
		color.g + (1.0 - color.g) * factor,
		color.b + (1.0 - color.b) * factor,
		color.a)
	
func _ready():
	time_of_calling_ready = Time.get_ticks_msec()
	stun_sprite.visible = false
	
	progress_bar.value = 0
	progress_bar.set_fill_color(player_color)
	progress_bar.set_background_color(lighten_color(player_color, 0.5))

	name_label.text = player_name
	name_label.add_theme_color_override("font_color", player_color)

func _process(delta):
	
	if not visible:
		return
	
	# Remove stun after some time
	if get_ms_since_being_stunned() > stunned_ms / Engine.time_scale:
		unstun()
		
	if is_eating():
		if get_ms_since_started_eating() > eating_ms / Engine.time_scale:
			consume_food()
	else:
		move(delta)
	
	# Set the food's position relative to the player.
	if self.food != null:
		if animation == "walking_down":
			self.food.position = Vector2(-1, 14)
		if animation == "walking_up":
			self.food.position = Vector2(-1, -14)
		if animation == "walking_right":
			self.food.position = Vector2(14, 6)
		if animation == "walking_left":
			self.food.position = Vector2(-14, 6)
				
func _on_area_area_entered(area):
	
	if not visible:
		return
		
	if self.food == null:
		# Check if the parent of the entered area is food
		var food = area.get_parent()
		if food is Food:
			take_food(food)
	
func is_eating():
	""" Returns true if currently eating. """
	
	# Cannot eat without food
	if time_started_eating != null and self.food == null:
		push_error("Food is null but rat think its eating.")
		
	return self.food != null and time_started_eating != null
	
func is_stunned():
	""" Returns true if currently stunned. """
	return get_ms_since_being_stunned() < stunned_ms
	
func is_invulnerable():
	""" When food just got picked up, rat is invulnerable. """
	return get_ms_since_pickup() < invulnerable_ms
	
func move(delta):
	
	var velocity = get_velocity()
	var animation_name = ""

	# Set correct animation_name
	if velocity.y > 0:
		animation_name = "walking_down"
	if velocity.y < 0:
		animation_name = "walking_up"
	if velocity.x > 0:
		animation_name = "walking_right"
	if velocity.x < 0:
		animation_name = "walking_left"
		
	# Bring food visually behind rat
	if self.food != null:
		self.food.z_as_relative = true
		self.food.z_index = -1
		
	# Handle animation
	if velocity == Vector2(0, 0) or is_eating():
		stop_walk_animation()
	elif velocity != last_velocity and animation_name != "":
		play(animation_name)
		
	var weight_multiplier = self.food.get_speed_multiplier() if self.food != null else 1
	var stun_multiplier = pow(1.0 * get_ms_since_being_stunned() / stunned_ms, 6) if is_stunned() else 1
	var pickup_multiplier = 1.2 if is_invulnerable() else 1
#	var stun_multiplier = 0 if is_stunned() else 1
#	print("stun_multiplier = " + str(stun_multiplier))
	velocity = velocity.normalized() * weight_multiplier * stun_multiplier * pickup_multiplier * speed * delta
	
	# Computer must not overshoot
	if is_computer and self.best_food:
		var distance_to_best_food = (self.best_food.global_position - global_position).length()
		if velocity.length() > distance_to_best_food:
			velocity = distance_to_best_food * velocity.normalized()
		
	position += velocity

	last_velocity = velocity

func take_food(food: Food):
	""" Takes the given food to carry it. Returns true on success. """
	
	# Dont take if drop key is pressed
	if not is_computer and Input.is_key_pressed(key_drop):
		return false
			
	if self.food == food:
		report("Already has same food.")
		return false
				
	if is_stunned() or food.just_dropped_by_rat(self):
#		report("Denied taking food.")
		return false
		
	if food.health == 0:
		report("Food is already eaten.")
		return false
	
	report("Taking food.")
	
	time_of_pickup = Time.get_ticks_msec()
	
	# Old rat needs to drop food first
	if food.rat != null:
		var rat: Rat = food.rat
		if rat.is_invulnerable():
			return false
			
#		if rat.is_eating():
		rat.stun()
		rat.drop_food()
		# Stun when rat was eating

		
	self.food = food
	food.attach(self)
	
	# Immediatly start eating as computer
	if is_computer:
		start_eating()
		
	return true
			
func drop_food():
	""" Drops the current food. """
	report("Dropping food.")
	self.food.drop(self)
	self.food = null
	time_started_eating = null

func start_eating():
	""" Starts eating food (needs some time)."""
		
	if self.food == null or self.food.health == 0:
		push_error("Food must not be null and must have health.")
		
	time_started_eating = Time.get_ticks_msec()
	report("Started eating at " + str(time_started_eating) + ", health = " + str(self.food.health))
	
	stop_walk_animation()
	audio_eating.play()
		
func stop_eating():
	""" Stops eating food (needs some time)."""
	if self.food == null:
		push_error("Food cannot be null")
		return
	audio_eating.stop()
	time_started_eating = null
#	report("Stopping eating")

func consume_food():
	""" Consumes one food stack. Immediatly continue eating if food is not empty. """
	
	if self.food == null or self.food.health == 0:
		push_error("Food must be not null and must have health.")
		return
		
	report("Consuming food")
	
	stop_eating()
	self.food.bite_off()
	if self.food.health == 0:
		self.food = null
		time_started_eating = null
	if self.food != null:
		if is_computer or Input.is_key_pressed(key_eat):
			start_eating()
			
var time_set_best_food = null
		
func get_velocity():
	if is_computer:
		var best_food = 0  # Set a high initial distance
		var best_score = 0  # Set a high initial distance
		
		for food in food_spawner.foods:
			var score = food.get_score(self)
			if score > best_score:# and len(food.hunting_rats) == 0:
				best_food = food
				best_score = score
		
		if best_food:
			if self.best_food != best_food:
				self.best_food = best_food
				time_set_best_food = Time.get_ticks_msec()
#			if closest_food != target_food:
#				if target_food:
#					target_food.untarget(self)
#				closest_food.target(self)
#
			var vector_to_best_food: Vector2 = best_food.global_position - global_position
			
			# Take close food
			if vector_to_best_food.length() < 5 and self.food and self.food != best_food:
				take_food(best_food)
				
			return vector_to_best_food
		else:
			# No food found, don't move
			self.target_food = null
			return Vector2(0, 0)
	else:
		var velocity = Vector2(0, 0)
		if Input.is_key_pressed(key_down):
			velocity.y += 1
		if Input.is_key_pressed(key_up):
			velocity.y -= 1
		if Input.is_key_pressed(key_right):
			velocity.x += 1
		if Input.is_key_pressed(key_left):
			velocity.x -= 1
		return velocity
	
func stun():
	""" Stuns the rat which keeps it from moving fast. """
	audio_squeaking.play()
	stun_sprite.play()
	stun_sprite.visible = true
	time_being_stunned = Time.get_ticks_msec()
	
func unstun():
	""" Unstuns the rat which allows it again to move fast. """
	stun_sprite.stop()
	stun_sprite.visible = false
	time_being_stunned = null
		
func get_ms_since_started_eating():
	if time_started_eating == null:
		return 99999
	return Time.get_ticks_msec() - time_started_eating
	
func get_ms_since_pickup():
	if time_of_pickup == null:
		return 99999
	return Time.get_ticks_msec() - time_of_pickup
	
func get_ms_since_being_stunned():
	if time_being_stunned == null:
		return 99999
	return Time.get_ticks_msec() - time_being_stunned
	
func stop_walk_animation():
	pause()
	set_frame_and_progress(1, 0)
	
func report(text: String):
	print(name + ": " + text)
	
func get_saturation():
	""" Returns saturation normalized (from 0 to 1). """
	return progress_bar.value / progress_bar.max_value
	
func increase_saturation(increment):
	progress_bar.value += increment
	if progress_bar.value >= progress_bar.max_value:
		var time_in_seconds = 0.001 * (Time.get_ticks_msec() - time_of_calling_ready)
		restart_label.visible = true
		restart_label.modulate = player_color
		restart_label.text = "Time: " + str(time_in_seconds) + " s\nPress R to restart."
		winner_label.visible = true
		winner_label.modulate = player_color
		winner_label.text = player_name + " wins!"
		Engine.time_scale = 0
		
func _input(event):
	
	if not visible or not event is InputEventKey:
		return
		
	var key_pressed = event.is_pressed()
	var is_echo = event.is_echo()
	
	if event.keycode == KEY_R and key_pressed:
		get_tree().reload_current_scene()
		Engine.time_scale = 1
		
	# P means print debug output
	if OS.is_debug_build() and event.keycode == KEY_P and key_pressed:
		print("time_started_eating = " + str(self.time_started_eating) + "\n" +
			  "get_ms_since_started_eating() = " + str(self.get_ms_since_started_eating()))		
			
	if is_computer:
		if OS.is_debug_build() and event.keycode == KEY_O and key_pressed:
			# O means computer let drop food
			drop_food()
			
		# Disable computer
		if can_become_player and event.keycode in [key_up, key_down, key_right, key_left, key_eat, key_drop]:
			self.is_computer = false
	else:
		if event.keycode == key_drop and key_pressed and self.food != null:
			drop_food()
				
		# Speed up
		if OS.is_debug_build() and key_pressed:
			if event.keycode == KEY_2:
				Engine.time_scale = 2
			if event.keycode == KEY_4:
				Engine.time_scale = 4
			if event.keycode == KEY_8:
				Engine.time_scale = 8
			if event.keycode == KEY_0:
				Engine.time_scale = 1
								
		if event.keycode == key_eat and not is_echo:
			# When space is just pressed, set the time for that
			if key_pressed and self.food != null:
				start_eating()
				
			# When space is just released, stop eating BUT ONLY if eating not finished in next 200 ms
			var time_until_eaten = self.eating_ms - get_ms_since_started_eating()
#			print("time_until_eaten = " + str(time_until_eaten))
			if not key_pressed and time_until_eaten > 200:
				stop_eating()
# Nice to know
#		if node.has_script("res://Nut.gd"):
#		parent.get_class() == "ClassName"
#		food.reparent(self)
