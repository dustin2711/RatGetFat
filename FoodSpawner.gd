extends Node2D

class_name FoodSpawner

# Is automatic spawning enabled?
@export var is_active = true
# Time between two spawn in milliseconds
@export var spawn_time_delta_at_no_food: int = 1000
@export var spawn_time_delta_at_max_food_count: int = 10000
@export var max_food_count: int = 20

# Distance in pixels
@export var min_spawn_distance = 40

var time_of_last_spawn: int = 0

var quarter_camera_size = Vector2(0, 0)
var camera_position = Vector2(0, 0)
var camera_zoom: float = 1

var foods = [] # type hinting for lists is not supported :( (https://github.com/godotengine/godot-proposals/issues/192)
var rats = []

@onready var root = get_parent()
@onready var camera: Camera2D = root.find_child("Camera")

func _ready():
	for node in root.get_children():
		if node is Rat:
			rats.append(node)
#			print(node.name)
	pass
	
func _process(delta):
	if len(foods) > max_food_count:
		return
		
	var ms_since_spawn = Time.get_ticks_msec() - time_of_last_spawn
	var current_time_delta = spawn_time_delta_at_no_food + spawn_time_delta_at_max_food_count / max_food_count * len(foods)
	if ms_since_spawn > current_time_delta / Engine.time_scale:
		spawn()
		
func spawn():
	""" Spawns a food randomly in the camera area. """
	# Update current camera parameters
	quarter_camera_size = 0.40 * camera.get_viewport_rect().size / 2
	camera_position = camera.get_screen_center_position()
	camera_zoom = camera.zoom.x
	
	var food = load_food().instantiate()
	var position = get_start_position(0)
	food.global_position = position
	foods.append(food)
	print("Spawned food at " + str(position))
	add_child(food)
	
	time_of_last_spawn = Time.get_ticks_msec()
	
func get_start_position(loop):
	""" Returns a position inside the camera area. """
	var position = self.camera_position
	# Because zoom level is 2, we need to half the values again
	position.x += randf_range(-quarter_camera_size.x, quarter_camera_size.x)
	position.y += randf_range(-quarter_camera_size.y, quarter_camera_size.y)
#	print("food position = " + str(position))

	# Prevent food spawned on similar positions (maximum 20 tries)
	if loop < 20:
		for other_object in rats + foods:
			if other_object.global_position.distance_to(position) < min_spawn_distance:
	#			print("other object position = " + str(other_object.global_position))
				return get_start_position(loop + 1)
			
	return position

func load_food():
#	return load("res://Scenes/melon.tscn")
#	return load("res://Scenes/nut.tscn")
#	return load("res://Scenes/cheese.tscn")
	var random = randf_range(0, 100)
	if random <= 30:
		return load("res://Scenes/nut.tscn")
	elif random > 30 and random < 75:
		return load("res://Scenes/melon.tscn")
	elif random >= 75:
		return load("res://Scenes/cheese.tscn")
	else:
		assert(false)

# K Key spawns food
func _input(event):
	if event is InputEventKey:
		var just_pressed = event.is_pressed()# and not event.is_echo()
		if just_pressed and event.keycode == KEY_1:
			spawn()
		

func randomBool():
	return randi() % 2 == 0
	
func randomSign():
	return 1 if randomBool() else -1
	
