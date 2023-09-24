extends AnimatedSprite2D

class_name Rat

@export var player_name: String = "SP1"
@export var player_color: Color = Color.RED
@export var speed = 200  # Adjust this value to control the movement speed.
@export var stunned_ms = 1500  # Adjust this value to control the movement speed.
@export var eating_ms = 900  # Adjust this value to control the movement speed.
@export var progress_bar: ColorizedProgressBar = null

var food: Food = null
@onready var root = get_parent()
@onready var food_spawner = root.find_child("FoodSpawner")
@onready var audio_eating: AudioStreamPlayer2D = $AudioEating
@onready var audio_squeaking: AudioStreamPlayer2D = $AudioSqueaking
@onready var stun_sprite: AnimatedSprite2D = $Stun
@onready var name_label: Label = $Name

# When this is != null, then currently food is eaten
var time_started_eating = null
var time_being_stunned = null

var last_velocity = Vector2(0, 0)

func lighten_color(color: Color, factor: float) -> Color:
	""" 0 means no change, 1 means fully lighten. """
	factor = clamp(factor, 0.0, 1.0)
	# Calculate the new color components by increasing them
	return Color(color.r + (1.0 - color.r) * factor,
		color.g + (1.0 - color.g) * factor,
		color.b + (1.0 - color.b) * factor,
		color.a)
	
func _ready():
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
	return time_being_stunned != null
	
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
		
	if self.food != null:
		# Bring food only to front if walking down
		self.food.z_as_relative = true
		self.food.z_index = -1
#		1 if animation_name == "walking_down" else -1

	if velocity == Vector2(0, 0) or is_eating():
		stop_walk_animation()
	elif velocity != last_velocity and animation_name != "":
		play(animation_name)

	var weight_multiplier = self.food.get_speed_multiplier() if self.food != null else 1
	var stun_multiplier = pow(1.0 * get_ms_since_being_stunned() / stunned_ms, 4) if is_stunned() else 1
#	print("stun_multiplier = " + str(stun_multiplier))
	velocity = velocity.normalized() * weight_multiplier * stun_multiplier * speed * delta
	position += velocity

	last_velocity = velocity

func take_food(food):
	""" Takes the given food to carry it. Returns true on success. """
	
	if self.food == food:
		report("Already has same food.")
		return false
				
	if is_stunned() or food.get_ms_since_drop(self) < 500:
		report("Denied taking food.")
		return false
		
	if food.health == 0:
		report("Food is already eaten.")
		return false
	
	report("Taking food.")
	
	# Old rat needs to drop food first
	if food.rat != null:
		food.rat.stun()
		food.rat.drop_food()
		
	self.food = food
	food.attach(self)
	
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
		push_error()
	audio_eating.stop()
	time_started_eating = null
#	report("Stopping eating")
		
func consume_food():
	""" Consumes one food stack. """
	
	if self.food == null or self.food.health == 0:
		push_error("Food must be not null and must have health.")
		
	report("Consuming food")
	stop_eating()
	self.food.bite_off()
	if self.food.health == 0:
		self.food = null
		time_started_eating = null
			
func get_velocity():
	""" Overriden in child class. """
	return Vector2(0, 0)
	
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
	
func get_ms_since_being_stunned():
	if time_being_stunned == null:
		return 99999
	return Time.get_ticks_msec() - time_being_stunned
	
func stop_walk_animation():
	pause()
	set_frame_and_progress(1, 0)
	
func report(text: String):
	print(name + ": " + text)

func increase_saturation(increment):
	progress_bar.value = clamp(progress_bar.value + increment, 0, progress_bar.max_value)
	if progress_bar.value == progress_bar.max_value:
		Engine.time_scale = 0

# Nice to know
#		if node.has_script("res://Nut.gd"):
#		parent.get_class() == "ClassName"
#		food.reparent(self)
