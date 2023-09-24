extends Rat

func get_velocity():
	var velocity = Vector2(0, 0)
	if Input.is_key_pressed(KEY_S):
		velocity.y += 1
	if Input.is_key_pressed(KEY_W):
		velocity.y -= 1
	if Input.is_key_pressed(KEY_D):
		velocity.x += 1
	if Input.is_key_pressed(KEY_A):
		velocity.x -= 1
	return velocity

func consume_food():
	""" Immediatly continue eating if food is not empty. """
	super.consume_food()
	
	if self.food != null and Input.is_key_pressed(KEY_SPACE):
		start_eating()
