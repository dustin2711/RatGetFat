extends AnimatedSprite2D

@export var speed = 200  # Adjust this value to control the movement speed.
@export var mouth_distance = Vector2(100, 50)

var food = null
@onready var audio_eating = $AudioEating

# Is null when no space is pressed currently
var time_space_pressed = null

var last_velocity = Vector2(0, 0)


func _ready():
	pass 

func get_ms_since_space_down():
	if time_space_pressed == null:
		return 99999
	return Time.get_ticks_msec() - time_space_pressed
	 
func _process(delta):
	if Input.is_key_pressed(KEY_Q) and self.food != null:
		drop_food()

	var eating = Input.is_key_pressed(KEY_SPACE) and self.food != null
	
	if eating:
		# Space pressed: eating
		if time_space_pressed != null:
			if get_ms_since_space_down() > 800:
				consume()
				time_space_pressed = null
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
	if event is InputEventKey:
		if event.keycode == KEY_SPACE:
			# When space is just pressed, set the time for that
			var just_pressed = event.is_pressed() and not event.is_echo()
			if just_pressed and self.food != null:
				time_space_pressed = Time.get_ticks_msec()
				stop_animation()
				audio_eating.play()
				
			# When space is just released, set the time to null
			var just_released = !event.is_pressed() and not event.is_echo()
			if just_released:
				audio_eating.stop()
#				# Release food when released immediatly
#				if get_ms_since_space_down() < 200:
#					self.food.drop(self)
#					self.food = null
				time_space_pressed = null

func drop_food():
	self.food.drop(self)
	self.food = null
	
func move(delta):
	var velocity = Vector2(0, 0)
	
	var animation = ""
	# No space pressed: free to move
	if Input.is_key_pressed(KEY_S):
		animation = "walking_down"
		velocity.y += 1
	if Input.is_key_pressed(KEY_W):
		animation = "walking_up"
		velocity.y -= 1		
	if Input.is_key_pressed(KEY_D):
		animation = "walking_right"
		velocity.x += 1
	if Input.is_key_pressed(KEY_A):
		animation = "walking_left"
		velocity.x -= 1
		
	if velocity != last_velocity:
		play(animation)
		
	if velocity == Vector2(0, 0):
		stop_animation()
		
	var weight_multiplier = 1
	if self.food != null:
		weight_multiplier = self.food.get_speed_multiplier()
	velocity = velocity.normalized() * weight_multiplier * speed * delta
	position += velocity

	last_velocity = velocity
	
func stop_animation():
	pause()
	set_frame_and_progress(1, 0)
	
func consume():
	if self.food != null:
		audio_eating.stop()
		if self.food.reduce():
			self.food = null
	
func _on_area_area_entered(area):
	# Check if the parent of the entered area is food
	var food = area.get_parent()
	if food and food.is_in_group("Food") and food.get_ms_since_drop(self) > 100:
		self.food = food
#		print("Collecting food.")
		food.reparent(self)



# Nice to know
#		if node.has_script("res://Nut.gd"):
#		parent.get_class() == "ClassName"
#		food.reparent(self)
