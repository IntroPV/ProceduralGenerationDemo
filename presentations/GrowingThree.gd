extends Node2D

## Algoritmo adaptado de http://pcg.wikidot.com/pcg-algorithm:maze

const e = 2.718281
enum {
	WALL, EMPTY, UNDETERMINED_EXPOSED, UNDETERMINED_UNEXPOSED
}

export var MAP_SIZE = Vector2(40,40)
export var MAP_ORIGIN = Vector2(28,0)
export(int, -1, 10) var branchrate = 0


onready var tilemap = $TileMap
onready var timer = $Timer
onready var empty_cell = $TileMap.tile_set.find_tile_by_name("empty")
onready var floor_cell = $TileMap.tile_set.find_tile_by_name("floor")
onready var wall_cell = $TileMap.tile_set.find_tile_by_name("wall")

var field = []
var frontier = []
var delay = 0.05
var use_delay = true

func _ready():
	randomize()

func _on_HSlider_value_changed(value):
	$BranchRateLabel.text = "Branch Rate: %f" % value
	branchrate = value
	_generate_maze_matrix()

func _clean_map():
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			tilemap.set_cellv(Vector2(x + MAP_ORIGIN.x,y + MAP_ORIGIN.y), empty_cell)

func _on_ShouldDelayCheckbox_toggled(button_pressed):
	use_delay = button_pressed

func _on_Randomize_pressed():
	_generate_maze_matrix()

func _generate_maze_matrix():
	_clean_map()
	
	field = []
	frontier = []
	
	for y in MAP_SIZE.y:
		var row = []
		for x in MAP_SIZE.x:
			row.append(UNDETERMINED_UNEXPOSED)
			
		field.append(row)
		
	#choose an original point at random and carve it out.
	var xchoice = randi() % int(MAP_SIZE.x - 1)
	var ychoice = randi() % int(MAP_SIZE.y - 1)
	print("CHOICE x: ", xchoice, "  Y: ", ychoice)
	carve(ychoice,xchoice)
	
	while(len(frontier)):
		if use_delay:
			timer.set_wait_time(0.05)
			timer.one_shot = true
			timer.start()
			yield(timer, "timeout")
		_walk_map()
    
	#set unexposed cells to be walls
	for y in MAP_SIZE.y:
		for x in MAP_SIZE.x:
			if field[y][x] == UNDETERMINED_UNEXPOSED:
				field[y][x] = WALL
				
	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var cell_type
			if field[y][x] == WALL:
				cell_type = wall_cell
			else:
				cell_type = floor_cell
			
			tilemap.set_cellv(Vector2(x + MAP_ORIGIN.x,y + MAP_ORIGIN.y), cell_type)
				

func _walk_map():
	#parameter branchrate:
	#zero is unbiased, positive will make branches more frequent, negative will cause long passages
	#this controls the position in the list chosen: positive makes the start of the list more likely,
	#negative makes the end of the list more likely
	
	#large negative values make the original point obvious
	
	#select a random edge
	var pos = randf()
	pos = pow(pos, pow(e, -branchrate))
	var choice = frontier[int(pos*len(frontier))]
	if check(choice.x, choice.y):
		carve(choice.x, choice.y)
		tilemap.set_cellv(Vector2(choice.x + MAP_ORIGIN.x,choice.y + MAP_ORIGIN.y), floor_cell)
	else:
		harden(choice.x, choice.y)
		tilemap.set_cellv(Vector2(choice.x + MAP_ORIGIN.x,choice.y + MAP_ORIGIN.y), wall_cell)
		
	frontier.remove(frontier.find(choice))

func carve(y, x):
	# Make the cell at y,x a space.
	#
	# Update the fronteer and field accordingly.
	# Note: this does not remove the current cell from frontier, it only adds new cells.
	
	var extra = []
	field[y][x] = EMPTY

	if x > 0:
		if field[y][x-1] == UNDETERMINED_UNEXPOSED:
			field[y][x-1] = UNDETERMINED_EXPOSED
			extra.append(Vector2(y,x-1))
	if x < MAP_SIZE.x - 1:
		if field[y][x+1] == UNDETERMINED_UNEXPOSED:
			field[y][x+1] = UNDETERMINED_EXPOSED
			extra.append(Vector2(y,x+1))
	if y > 0:
		if field[y-1][x] == UNDETERMINED_UNEXPOSED:
			field[y-1][x] = UNDETERMINED_EXPOSED
			extra.append(Vector2(y-1,x))
	if y < MAP_SIZE.y - 1:
		if field[y+1][x] == UNDETERMINED_UNEXPOSED:
			field[y+1][x] = UNDETERMINED_EXPOSED
			extra.append(Vector2(y+1,x))
			
	extra.shuffle()
	
	for e in extra:
		frontier.append(e)

func harden(y, x):
	#Make the cell at y,x a wall.
	field[y][x] = WALL

func check(y, x, nodiagonals = true):
	#Test the cell at y,x: can this cell become a space?
	#
	#true indicates it should become a space,
	#false indicates it should become a wall.

	
	var edgestate = 0
	if x > 0:
		if field[y][x-1] == EMPTY:
			edgestate += 1
	if x < MAP_SIZE.x-1:
		if field[y][x+1] == EMPTY:
			edgestate += 2
	if y > 0:
		if field[y-1][x] == EMPTY:
			edgestate += 4
	if y < MAP_SIZE.y-1:
		if field[y+1][x] == EMPTY:
			edgestate += 8
	
	if nodiagonals:
		#if this would make a diagonal connecition, forbid it
		#the following steps make the test a bit more complicated and are not necessary,
		#but without them the mazes don't look as good
		if edgestate == 1:
			if x < MAP_SIZE.x-1:
				if y > 0:
					if field[y-1][x+1] == EMPTY:
						return false
				if y < MAP_SIZE.y-1:
					if field[y+1][x+1] == EMPTY:
						return false
			return true
		elif edgestate == 2:
			if x > 0:
				if y > 0:
					if field[y-1][x-1] == EMPTY:
						return false
				if y < MAP_SIZE.y-1:
					if field[y+1][x-1] == EMPTY:
						return false
			return true
		elif edgestate == 4:
			if y < MAP_SIZE.y-1:
				if x > 0:
					if field[y+1][x-1] == EMPTY:
						return false
				if x < MAP_SIZE.x-1:
					if field[y+1][x+1] == EMPTY:
						return false
			return true
		elif edgestate == 8:
			if y > 0:
				if x > 0:
					if field[y-1][x-1] == EMPTY:
						return false
				if x < MAP_SIZE.x-1:
					if field[y-1][x+1] == EMPTY:
						return false
			return true
		return false
	else:
		#diagonal walls are permitted
		if  [1,2,4,8].count(edgestate):
			return true
		return false


