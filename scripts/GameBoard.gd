extends Node2D

# TileMap doesnt have borders, set max size
var MAX_TILE_X = 7
var MAX_TILE_Y = 10
# Number of ships for the player
var FLEET_SIZE = 10

# edit/attack mode
var is_plan_phase = false
# list for player ships coordinates, es: [(5, 2), (3, 4), ...]
var ships_positions = []


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Detect user-clicked tile
func _input(event):
    if Input.is_action_pressed("lmb_click"):
        var selected_tile = check_valid_tile(event.position)
        if not is_plan_phase:
            print("Not in plan phase")
        elif not selected_tile:
            print("Invalid tile click")
        elif selected_tile in ships_positions:
            # there is already a ship here, remove it
            print("Removing ship in " + str(selected_tile))
            ships_positions.erase(selected_tile)
        elif len(ships_positions) < FLEET_SIZE:
            # add new ship
            print("Ship in " + str(selected_tile))
            ships_positions.append(selected_tile)
        else:
            print("Max fleet capacity reached")


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
