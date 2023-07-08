extends Node2D

# TileMap doesnt have borders, set max size
const MAX_TILE_X = 7
const MAX_TILE_Y = 10
# Number of ships for the player
const FLEET_SIZE = 10
# Aliases for TileMap and TileSet resource ids
# [FIXME] maybe use @onready?
const MAP_LAYER_SHIPS = 1
const PLAYER_SHIP_TILESET = 6

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
    # https://dev.to/sanijalal/godot-one-mouse-click-two-events-2615
    if event is InputEventMouseButton and event.is_pressed():
        var selected_tile = check_valid_tile(event.position)
        if not is_plan_phase:
            print("Not in plan phase")
        elif not selected_tile:
            print("Invalid tile click")
        elif selected_tile in ships_positions:
            # there is already a ship here, remove it
            print("Removing ship in " + str(selected_tile))
            ships_positions.erase(selected_tile)
            $TileMap.set_cell(MAP_LAYER_SHIPS, selected_tile, -1, Vector2i(0, 0))
        elif len(ships_positions) < FLEET_SIZE:
            # add new ship
            print("Ship in " + str(selected_tile))
            ships_positions.append(selected_tile)
            $TileMap.set_cell(MAP_LAYER_SHIPS, selected_tile, PLAYER_SHIP_TILESET, Vector2i(0, 0))
        else:
            print("Max fleet capacity reached")


# InputEventMouseButton position is absolute, not relative to map
# We remove the scene padding and return local Vector2D
func _normalize_position(pos):
    pos.x = pos.x - $TileMap.position.x
    pos.y = pos.y - $TileMap.position.y
    return pos


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
