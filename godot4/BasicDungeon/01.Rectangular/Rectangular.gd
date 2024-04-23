extends Node2D


@export var level_size := Vector2(100, 80)
@export var rooms_size := Vector2(10, 14)
@export var rooms_max := 15

@onready var level: TileMap = $Level
@onready var camera: Camera2D = $Camera2D
@onready var zscale = Vector2(1,1)
@onready var data := {}
@onready var rooms := []

func _ready() -> void:
	_setup_camera()
	_generate()
	
func _clear() -> void:
	level.clear()
	level.clear_layer(0)
	rooms.clear()
	data.clear()
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		_clear()
		_setup_camera()
		_generate()
	if event.is_action_pressed("zoom"):
		_center_and_zoom_random_room()
		
func _center_and_zoom_random_room():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var randi = rng.randi_range(0,rooms.size()-1)
		var selected_room = rooms[randi]
		print(selected_room)
		

func _setup_camera() -> void:
	camera.position = level.map_to_local(level_size / 2)
	var z := 8 / maxf(level_size.x, level_size.y)
	camera.zoom = Vector2(z, z)

func _generate() -> void:
	_clear()
	for vector in _generate_data():
		level.set_cell(0, vector, 0, Vector2i.ZERO, 0)


func _generate_data() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for r in range(rooms_max):
		var room := _get_random_room(rng)
		if _intersects(rooms, room):
			continue

		_add_room(data, rooms, room)
		if rooms.size() > 1:
			var room_previous: Rect2 = rooms[-2]
			_add_connection(rng, data, room_previous, room)
	return data.keys()


func _get_random_room(rng: RandomNumberGenerator) -> Rect2:
	var width := rng.randi_range(rooms_size.x, rooms_size.y)
	var height := rng.randi_range(rooms_size.x, rooms_size.y)
	var x := rng.randi_range(0, level_size.x - width - 1)
	var y := rng.randi_range(0, level_size.y - height - 1)
	return Rect2(x, y, width, height)


func _add_room(data: Dictionary, rooms: Array, room: Rect2) -> void:
	rooms.push_back(room)
	for x in range(room.position.x, room.end.x):
		for y in range(room.position.y, room.end.y):
			data[Vector2(x, y)] = null


func _add_connection(
	rng: RandomNumberGenerator, data: Dictionary, room1: Rect2, room2: Rect2
) -> void:
	var room_center1 := (room1.position + room1.end) / 2
	var room_center2 := (room2.position + room2.end) / 2
	if rng.randi_range(0, 1) == 0:
		_add_corridor(data, room_center1.x, room_center2.x, room_center1.y, Vector2.AXIS_X)
		_add_corridor(data, room_center1.y, room_center2.y, room_center2.x, Vector2.AXIS_Y)
	else:
		_add_corridor(data, room_center1.y, room_center2.y, room_center1.x, Vector2.AXIS_Y)
		_add_corridor(data, room_center1.x, room_center2.x, room_center2.y, Vector2.AXIS_X)


func _add_corridor(data: Dictionary, start: int, end: int, constant: int, axis: int) -> void:
	for t in range(min(start, end), max(start, end) + 1):
		var point := Vector2.ZERO
		match axis:
			Vector2.AXIS_X: point = Vector2(t, constant)
			Vector2.AXIS_Y: point = Vector2(constant, t)
		data[point] = null


func _intersects(rooms: Array, room: Rect2) -> bool:
	var out := false
	for room_other in rooms:
		if room.intersects(room_other):
			out = true
			break
	return out
