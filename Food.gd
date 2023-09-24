extends AnimatedSprite2D

class_name Food

var health = 3
var max_health = 3

var rat: Rat = null
var time_of_drop_by_rat = {}

@export var outer_saturation: int = 1
@export var middle_saturation: int = 1
@export var inner_saturation: int = 1

@export var outer_speed_multiplier: float = 0.7
@export var middle_speed_multiplier: float = 0.8
@export var inner_speed_multiplier: float = 0.9

@onready var spawner: FoodSpawner = get_parent()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	animation = "Health3"

func get_speed_multiplier():
	if health == 3:
		return outer_speed_multiplier
	elif health == 2:
		return middle_speed_multiplier
	elif health == 1:
		return inner_speed_multiplier
	else:
		return 1

func get_ms_since_drop(rat: Rat):
	""" Gets the time since food was dropped by rat. """
	var time_of_drop = time_of_drop_by_rat.get(rat)
	if time_of_drop == null:
		return 9999
	return Time.get_ticks_msec() - time_of_drop
	
func bite_off():
	""" Reduces the amount of this food by eating a bit. 
	Returns true when eaten. """
	
	assert(rat != null)
	
	if health == 3:
		rat.increase_saturation(outer_saturation)
	elif health == 2:
		rat.increase_saturation(middle_saturation)
	elif health == 1:
		rat.increase_saturation(inner_saturation)
		
	health -= 1
	
	if health == 2:
		animation = "Health2"
	elif health == 1:
		animation = "Health1"
	elif health <= 0:
		queue_free()
		spawner.foods.erase(self)
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
		
# Nice to know
#	material.set_shader_parameter("fillPortion", 1.0 * health / max_health)
