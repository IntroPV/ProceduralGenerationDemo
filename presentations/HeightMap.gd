extends Node2D

export var MAP_SIZE = Vector2(70,70)

export var height_clamp = 0.0

onready var tilemap = $TileMap
onready var empty_cell = $TileMap.tile_set.find_tile_by_name("empty")
onready var floor_cell = $TileMap.tile_set.find_tile_by_name("floor")
onready var wall_cell = $TileMap.tile_set.find_tile_by_name("wall")

var noise

func _ready():
	randomize()
	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 14
	noise.lacunarity = 1.5
	noise.persistence = 0.6
	
	generate_level()

func generate_level():

	for x in MAP_SIZE.x:
		for y in MAP_SIZE.y:
			var tile = tilemap.get_cellv(Vector2(x,y))
			if tile >= 0:
				tilemap.set_cellv(Vector2(x,y), _tile_for_position(x,y))
	
	# Esto actualiza el bitmask de los autotiles
	tilemap.update_bitmask_region(Vector2(0,0), MAP_SIZE)
	
func _tile_for_position(x:int, y:int) -> int:
	var height = noise.get_noise_2d(float(x), float(y))
	return floor_cell if height < height_clamp else wall_cell

func _on_HSlider_value_changed(value):
	height_clamp = value
	$FloodHeightLabel.text = "Floor Level: %f" % height_clamp
	generate_level()


func _on_Randomize_pressed():
	noise.seed = randi()
	generate_level()
