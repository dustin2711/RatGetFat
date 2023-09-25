extends AnimatedSprite2D

class_name Food

var do_not_pickup_after_drop_ms = 500  # Dont instant pickup dropped food

var health = 3
var max_health = 3

var hunting_rats = []
		
var rat: Rat = null
var time_of_drop_by_rat = {}

@export var outer_saturation: int = 1
@export var middle_saturation: int = 1
@export var inner_saturation: int = 1

@export var outer_speed_multiplier: float = 0.7
@export var middle_speed_multiplier: float = 0.8
@export var inner_speed_multiplier: float = 0.9

@onready var spawner: FoodSpawner = get_parent()

var saturation_by_health = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	animation = "Health3"
	saturation_by_health[3] = outer_saturation
	saturation_by_health[2] = middle_saturation
	saturation_by_health[1] = inner_saturation

func get_score(rat: Rat):
	""" The higher, the more like to go for this food. """
	
	# Increase score with decreasing distance to this rat
	var distance_to_rat_score = 1.0 / sqrt(self.global_position.distance_to(rat.global_position))
	
	# The longer same food is chased, the lower the score
	var boring_score = 1 if rat.time_set_best_food and (Time.get_ticks_msec() - rat.time_set_best_food) < 2000 else 0.25
	
	# Increase score with increasing distance to other rats
	var distance_to_other_rats_score = 1.0
	for other_rat in spawner.rats:
		if rat != other_rat:
			distance_to_other_rats_score += sqrt(self.global_position.distance_to(other_rat.global_position))
			
	# Increase score with saturation
	var saturation_score = saturation_by_health[health]
	
	# Increase score when owning rat is eating and decrease when owning rat is moving
	var moving_score = 1
	if self.rat != null:
		moving_score = 1.2 if self.rat.is_eating() else 0.8
		if self.rat.get_saturation() > 0.75:
			moving_score += 0.8
		elif self.rat.get_saturation() > 0.5:
			moving_score += 0.4
			
	return distance_to_rat_score * distance_to_other_rats_score * saturation_score * moving_score * boring_score # * randf_range(0.5, 2)
	
func get_speed_multiplier():
	if health == 3:
		return outer_speed_multiplier
	elif health == 2:
		return middle_speed_multiplier
	elif health == 1:
		return inner_speed_multiplier
	else:
		return 1

func just_dropped_by_rat(rat: Rat):
	""" Gets the time since food was dropped by rat. """
	var time_of_drop = time_of_drop_by_rat.get(rat)
	return time_of_drop and Time.get_ticks_msec() - time_of_drop < do_not_pickup_after_drop_ms

func bite_off():
	""" Reduces the amount of this food by eating a bit. 
	Returns true when eaten. """
	
	assert(rat != null)
	
	rat.increase_saturation(saturation_by_health[health])
		
	health -= 1
	
	if health == 2:
		animation = "Health2"
	elif health == 1:
		animation = "Health1"
	elif health <= 0:
		spawner.foods.erase(self)
		for rat in hunting_rats:
			self.untarget(rat)
		queue_free()
	else:
		push_error()

func drop(rat: Rat):
	""" Food is dropped and be parented to FoodSpawner. """
	time_of_drop_by_rat[rat] = Time.get_ticks_msec()
	self.rat = null
	call_deferred("reparent_to_spawner")
	
func attach(rat: Rat):
	""" Food is collected by rat. """
	self.rat = rat
	call_deferred("reparent_to_rat")

func reparent_to_spawner():
	reparent(self.spawner)
	
func reparent_to_rat():
	reparent(self.rat)
	
func target(rat: Rat):
	""" Makes the rat target the food. """
	if rat not in hunting_rats:
		hunting_rats.append(rat)
		rat.target_food = self
	
func untarget(rat: Rat):
	""" Makes the rat untarget the food. """
	if rat in hunting_rats:
		hunting_rats.erase(rat)
		rat.target_food = null
				
# Nice to know
#	material.set_shader_parameter("fillPortion", 1.0 * health / max_health)
