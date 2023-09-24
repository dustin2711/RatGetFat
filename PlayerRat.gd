extends Rat

@export var is_computer = true

@export var key_up = KEY_W
@export var key_down = KEY_S
@export var key_right = KEY_D
@export var key_left = KEY_A
@export var key_eat = KEY_SPACE
@export var key_drop = KEY_SHIFT

func get_velocity():
	if is_computer:
		var closest_food = null
		var closest_distance = 9999  # Set a high initial distance
		
		for food in food_spawner.foods:
			var distance = global_position.distance_to(food.global_position)
			if distance < closest_distance:
				closest_food = food
				closest_distance = distance
		
		if closest_food:
			var vector_to_closest_food : Vector2 = closest_food.global_position - global_position
			# Take close food
			if vector_to_closest_food.length() < 1 and self.food and self.food != closest_food:
				take_food(closest_food)
			var direction = vector_to_closest_food.normalized()
			return direction
		else:
			return Vector2(0, 0)  # No food found, don't move
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

func consume_food():
	""" Immediatly continue eating if food is not empty. """
	super.consume_food()
	
	if self.food != null:
		if is_computer or Input.is_key_pressed(key_eat):
			start_eating()
			
func take_food(food):
	if is_computer:
		if super.take_food(food):
			start_eating()
			return true
		return false
	elif not Input.is_key_pressed(key_drop):
		return super.take_food(food)

func _input(event):
	
	if not visible or not event is InputEventKey:
		return
		
	var key_pressed = event.is_pressed()
	
	# P means print debug output
	if event.keycode == KEY_P and event.is_pressed():
		print("time_started_eating = " + str(self.time_started_eating) + "\n" +
			  "get_ms_since_started_eating() = " + str(self.get_ms_since_started_eating()))		
			
	if is_computer:
		if event.keycode == KEY_O and key_pressed:
			# O means computer let drop food
			drop_food()
			
		# Disable computer
		if event.keycode in [key_up, key_down, key_right, key_left, key_eat, key_drop]:
			self.is_computer = false
	else:
		if event.keycode == key_drop and event.is_pressed() and self.food != null:
			drop_food()
				
		# Speed up
		if key_pressed:
			if event.keycode == KEY_2:
				Engine.time_scale = 2
			if event.keycode == KEY_4:
				Engine.time_scale = 4
			if event.keycode == KEY_8:
				Engine.time_scale = 8
			if event.keycode == KEY_0:
				Engine.time_scale = 1
								
		if event.keycode == key_eat:
			# When space is just pressed, set the time for that
			var just_pressed = event.is_pressed() and not event.is_echo()
			if just_pressed and self.food != null:
				start_eating()
				
			# When space is just released, stop eating BUT ONLY if eating not finished in next 200 ms
			var time_until_eaten = self.eating_ms - get_ms_since_started_eating()
			print("time_until_eaten = " + str(time_until_eaten))
			var just_released = !event.is_pressed() and not event.is_echo()
			if just_released and time_until_eaten > 200:
				stop_eating()
				


