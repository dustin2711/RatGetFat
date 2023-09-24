extends Node2D

class_name FoodSpawner

@export var is_active = true
@export var spawn_time_delta = 500 # ms
@export var spawn_time_delta_multiplier = 0.9
@export var min_spawn_time_delta = 200

@export var min_spawn_distance = 40

var frame = 0

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
	if is_active && frame % spawn_time_delta == 0:
		frame = 0
		# Shrink spawn_time_delta
		spawn_time_delta = int(clamp(spawn_time_delta_multiplier * spawn_time_delta, min_spawn_time_delta, 99999))
		spawn()
	frame += 1
#
func get_start_position(loop):

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
	var random = randi_range(0, 2)
	if random == 0:
		return load("res://Scenes/nut.tscn")
	elif random == 1:
		return load("res://Scenes/cheese.tscn")
	elif random == 2:
		return load("res://Scenes/melon.tscn")
		
# is overridden in child classes
func spawn():
	# Update current camera parameters
	quarter_camera_size = 0.47 * camera.get_viewport_rect().size / camera_zoom
	camera_position = camera.get_screen_center_position()
	camera_zoom = camera.zoom.x
	
	var food = load_food().instantiate()
	food.global_position = get_start_position(0)
	foods.append(food)
	add_child(food)
	print("Spawned food at " + str(food.global_position))

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
	
