extends AnimatedSprite2D

class_name Rat

@export var speed = 200  # Adjust this value to control the movement speed.

var food: Food = null
@onready var root = get_parent()
@onready var food_spawner = root.find_child("FoodSpawner")
@onready var audio_eating = $AudioEating

# Is null when no space is pressed currently
var time_started_eating = null

var last_velocity = Vector2(0, 0)

func _ready():
	pass 

func _process(delta):
	
	if not visible:
		return

	if time_started_eating != null and self.food != null:
		if get_ms_since_started_eating() > 800:
			consume_food()
	else:
		move(delta)
	
	# Set the nut's position relative to the player.
	if self.food != null:
		if animation == "walking_down":
			self.food.position = Vector2(-1, 14)
		if animation == "walking_up":
			self.food.position = Vector2(-1, -14)
		if animation == "walking_right":
			self.food.position = Vector2(14, 6)
		if animation == "walking_left":
			self.food.position = Vector2(-14, 6)
			
func _input(event):
	
	if not visible:
		return
		
	if event is InputEventKey:
				
		if event.keycode == KEY_Q and event.is_pressed() and self.food != null:
			drop_food()
		
		if event.keycode == KEY_SPACE:
			# When space is just pressed, set the time for that
			var just_pressed = event.is_pressed() and not event.is_echo()
			if just_pressed and self.food != null:
				start_eating()
				
			# When space is just released, stop eating
			var just_released = !event.is_pressed() and not event.is_echo()
			if just_released:
				stop_eating()
				
func _on_area_area_entered(area):
	
	if not visible:
		return
		
	if self.food == null:
		# Check if the parent of the entered area is food
		var food = area.get_parent()
		var className = food.get_class()
#		if food.has_script("your_script_name.gd"):
#			print("jo")
		if food and food is Food and food.get_ms_since_drop(self) > 100:
			take_food(food)
			
	
func take_food(food):
	print("Taking food.")
	self.food = food
	food.reparent(self)
		
func drop_food():
	print("Dropping food.")
	self.food.drop(self)
	self.food = null
	
func start_eating():
	print("Starting eating")
	time_started_eating = Time.get_ticks_msec()
	stop_walk_animation()
	audio_eating.play()
		
func stop_eating():
	print("Stopping eating")
	audio_eating.stop()
	time_started_eating = null
		
func consume_food():
	""" Consumes one food stack. Returns true when eaten. """
	if self.food == null:
		push_error("Food must be not null.")
		
	stop_eating()
	if self.food.reduce():
		self.food = null
			
func get_velocity():
	""" Overriden in child class. """
	return Vector2(0, 0)
	
func get_ms_since_started_eating():
	if time_started_eating == null:
		return 99999
	return Time.get_ticks_msec() - time_started_eating
		
func move(delta):
	
	var velocity = get_velocity()
	var animation = ""
	# No space pressed: free to move
	if velocity.y > 0:
		animation = "walking_down"
	if velocity.y < 0:
		animation = "walking_up"
	if velocity.x > 0:
		animation = "walking_right"
	if velocity.x < 0:
		animation = "walking_left"
		
	if velocity != last_velocity:
		play(animation)
		
	if velocity == Vector2(0, 0):
		stop_walk_animation()
		
	var weight_multiplier = 1
	if self.food != null:
		weight_multiplier = self.food.get_speed_multiplier()
	velocity = velocity.normalized() * weight_multiplier * speed * delta
	position += velocity

	last_velocity = velocity
	
func stop_walk_animation():
	pause()
	set_frame_and_progress(1, 0)
	



# Nice to know
#		if node.has_script("res://Nut.gd"):
#		parent.get_class() == "ClassName"
#		food.reparent(self)
