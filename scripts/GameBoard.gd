extends Node2D

# TileMap doesnt have borders, set max size
var MAX_TILE_X = 7
var MAX_TILE_Y = 10

# edit/attack mode
var is_plan_phase = false



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Detect user-clicked tile
func _input(event):
	if Input.is_action_pressed("lmb_click"):
		# print(event.position)
		print(check_valid_tile(event.position))


# InputEventMouseButton position is absolute, not relative to map
# We remove the scene padding and return local Vector2D
func _normalize_position(global_position):
	global_position.x = global_position.x - $TileMap.position.x
	global_position.y = global_position.y - $TileMap.position.y
	return global_position


# Ensure that clicked tile is a valid tile.
# Exclude out of map cells and Hero cells (first row)
func check_valid_tile(click_position):
	click_position = _normalize_position(click_position)
	var selected_tile = $TileMap.local_to_map(click_position)
	# print(str(click_position) + " - " + str(selected_tile))
	if selected_tile.x < 0 or selected_tile.y < 0:
		return false  # negative zone
	if selected_tile.x >= MAX_TILE_X:
		return false  # too far right
	if selected_tile.y >= MAX_TILE_Y:
		return false  # too far bottom
	if selected_tile.y == 0:
		return false  # first row is for hero
	return selected_tile
