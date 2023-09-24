extends Rat

func get_velocity():
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

func take_food(food):
	if super.take_food(food):
		start_eating()
		return true
	return false

func _input(event):
	
	if event is InputEventKey:
		if event.keycode == KEY_O and event.is_pressed():
			drop_food()
		
		# Print debug output
		if event.keycode == KEY_P and event.is_pressed():
			print("time_started_eating = " + str(self.time_started_eating) + "\n" +
				  "get_ms_since_started_eating() = " + str(self.get_ms_since_started_eating()))
				
func consume_food():
	""" Immediatly continue eating if food is not empty. """
	super.consume_food()
		
	if self.food != null:
		start_eating()
