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
		var direction = (closest_food.global_position - global_position).normalized()
		return direction
	else:
		return Vector2(0, 0)  # No food found, don't move

func take_food(food):
	super.take_food(food)
	start_eating()

func consume_food():
	""" Immediatly continue eating if food is not empty. """
	super.consume_food()
		
	if self.food != null:
		start_eating()
