extends Node2D

# http://donjon.bin.sh/d20/dungeon/
# http://donjon.bin.sh/code/dungeon/
# http://roguebasin.roguelikedevelopment.org/index.php?title=Cellular_Automata_Method_for_Generating_Random_Cave-Like_Levels

export var MAP_SIZE = Vector2(63,36)
export(int, 0, 30) var N_ROOMS = 25
export(int, 1, 8) var MIN_SEPARATION = 1
export(int, 1, 5) var DISPLACEMENT_TEST = 1
export(int, 1, 10000) var FAILED_ATTEMPTS_MAX = 5000

onready var tilemap = $TileMap
onready var empty_cell = $TileMap.tile_set.find_tile_by_name("empty")
onready var floor_cell = $TileMap.tile_set.find_tile_by_name("simple_floor")
onready var wall_cell = $TileMap.tile_set.find_tile_by_name("wall")

func _ready():
	randomize()
	var r = Rect2(Vector2(0,0), Vector2(3,5))
	
func _on_Randomize_pressed():
	_generate_rooms()
	
func _clear_tilemap():
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			tilemap.set_cellv(Vector2(x,y), wall_cell)
				
func _generate_rooms():
	_clear_tilemap()
	
	var placed = []
	var world = Rect2(Vector2(1,1), MAP_SIZE - Vector2.ONE)
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var failed_attempts = 0
	while len(placed) < N_ROOMS and failed_attempts < FAILED_ATTEMPTS_MAX:
		var variation_size = 1 - max(len(placed), 1) / N_ROOMS
		var variation = int(6 * variation_size)
		
		var w = float(2 + randi() % (4 + variation))
		var h = float(2 + randi() % (4 + variation))
		var pos = Vector2(1 + randi() % int(MAP_SIZE.x - w - 1), 1 + randi() % int(MAP_SIZE.y - h - 1))
		
		var center_candidate := Rect2(pos, Vector2(w, h)).grow(MIN_SEPARATION)
		var candidates := [center_candidate]
		
		# Esto no es indispensable, pero ayuda a que las habitaciones no queden tan separadas
		for dir in directions:
			var candidate = Rect2(center_candidate.position + dir * DISPLACEMENT_TEST, center_candidate.size)
			if world.encloses(candidate):
				candidates.append(candidate)
		
		candidates.shuffle()
		var should_append = true
		for r in placed:
			if not len(candidates):
				break
			else:
				var to_remove = _overlaping(candidates, r)
				for disposable in to_remove:
					candidates.remove(candidates.find(disposable))

		if len(candidates):
			placed.append(candidates[0])
			failed_attempts = 0
		else:
			failed_attempts += 1	

	var without_margins = []
	for enclosing in placed:
		without_margins.append(enclosing.grow(-MIN_SEPARATION))
	
	for r in without_margins:
		var pos = r.position
		for x in int(r.size.x):
			for y in int(r.size.y):
				tilemap.set_cellv(Vector2(pos.x + x, pos.y + y), floor_cell)
				
	tilemap.update_bitmask_region(Vector2(0,0), MAP_SIZE)
	
	print("Connecting rooms...")
	
	var connected = []
	var next = without_margins.pop_front()
	while len(without_margins) > 0:
		var closest = _find_closer_rect(without_margins, next)
		
		closest.shuffle()
		var target = closest[0]
		
		_connect_cells(next.position + next.size/2, target.position + target.size/2)
		connected.append(next)
		next = target
		without_margins.remove(without_margins.find(target))
	
	var target = _find_closer_rect(connected, next)[0]
	_connect_cells(next.position + next.size/2, target.position + target.size/2)
	
	tilemap.update_bitmask_region(Vector2(0,0), MAP_SIZE)	


func _find_closer_rect(list, r):
	var overlapping = []
	var expanding = r
	while not overlapping:
		expanding = expanding.grow(1)
		overlapping = _overlaping(list, expanding)
	
	return overlapping	
		
func _connect_cells(pos1:Vector2, pos2:Vector2):
	var start = pos1 if pos1.x <= pos2.x and pos1.y <= pos2.y else pos2
	var end = pos2 if start == pos1 else pos1
	var cursor = start
	
	while cursor.x < end.x or cursor.y < end.y:
		tilemap.set_cellv(Vector2(int(cursor.x), int(cursor.y)), floor_cell)
		
		if cursor.x < end.x and (cursor.y >= end.y or randf() > 0.5):
			cursor.x += 1
		elif cursor.y < end.y:
			cursor.y += 1
		

func _overlaping(list, rect:Rect2):
	var overlapers = []
	for c in list:
		if c.intersects(rect):
			overlapers.append(c)
			
	return overlapers