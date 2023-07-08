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
# Number of ships that should reach Earth to win
const SHIPS_TO_WIN = 3

# edit/attack mode
var is_plan_phase = false
# list of player ships coordinates, at start and at runtime
# format: [(5, 2), (3, 4), ...]
var battlefield_start = []
var battlefield_curr = []
var battlefield_winners = []


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Detect user-clicked tile, used for placing player ships
# during planning phase.
func _input(event):
    # https://dev.to/sanijalal/godot-one-mouse-click-two-events-2615
    if event is InputEventMouseButton and event.is_pressed():
        var selected_tile = get_clicked_tile(event.position)
        if not is_plan_phase:
            print("Not in plan phase")
        elif not selected_tile:
            print("Invalid tile click")
        elif selected_tile in battlefield_start:
            # there is already a ship here, remove it
            print("Removing ship in " + str(selected_tile))
            battlefield_start.erase(selected_tile)
            $TileMap.set_cell(MAP_LAYER_SHIPS, selected_tile, -1, Vector2i(0, 0))
        elif len(battlefield_start) < FLEET_SIZE:
            # add new ship
            print("Ship in " + str(selected_tile))
            battlefield_start.append(selected_tile)
            $TileMap.set_cell(MAP_LAYER_SHIPS, selected_tile, PLAYER_SHIP_TILESET, Vector2i(0, 0))
        else:
            print("Max fleet capacity reached")


# InputEventMouseButton position is absolute, not relative to map
# We remove the scene padding and return local Vector2D
func normalize_position(pos):
    pos.x = pos.x - $TileMap.position.x
    pos.y = pos.y - $TileMap.position.y
    return pos


# Ensure that clicked tile is a valid tile.
# Exclude out of map cells and Hero cells (first row)
func get_clicked_tile(click_position):
    click_position = normalize_position(click_position)
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


# Run when planning phase ends and game starts.
# Used to clear screen.
func start_game():
    $FireRange.visible = true
    for ship_coord in battlefield_start:
        $TileMap.set_cell(MAP_LAYER_SHIPS, ship_coord, -1, Vector2i(0, 0))


# Run when game ends and planning phase starts.
func reset_game():
    $FireRange.visible = false
    for ship_coord in battlefield_curr:
        $TileMap.set_cell(MAP_LAYER_SHIPS, ship_coord, -1, Vector2i(0, 0))
    battlefield_start = []
    battlefield_curr = []
    battlefield_winners = []


# Run at each turn, so each timer clock.
# Used to move and spawn player ships.
func next_turn():
    var battlefield_new = []
    var battlefield_to_clear = []
    var new_tile = false
    var next_row_index_to_spawn = 32

    # move active ships one-tile-up,
    # clean and re-draw ship
    for ship_coord in battlefield_curr:
        new_tile = ship_coord + Vector2i(0, -1)
        # discard winners, keep other invaders
        if new_tile.y < 0:
            $TileMap.set_cell(MAP_LAYER_SHIPS, ship_coord, -1, Vector2i(0, 0))
            battlefield_winners.append(new_tile)
        else:
            $TileMap.set_cell(MAP_LAYER_SHIPS, ship_coord, -1, Vector2i(0, 0))
            $TileMap.set_cell(MAP_LAYER_SHIPS, new_tile, PLAYER_SHIP_TILESET, Vector2i(0, 0))
            battlefield_new.append(new_tile)

    # find the next row to spawn (this is embarassing...)
    # min(coord.y for coord in battlefield_start)
    for ship_coord in battlefield_start:
        next_row_index_to_spawn = min(next_row_index_to_spawn, ship_coord.y)

    # spawn new ships
    for ship_coord in battlefield_start:
        if ship_coord.y == next_row_index_to_spawn:
            new_tile = Vector2i(ship_coord.x, MAX_TILE_Y-1)
            battlefield_new.append(new_tile)
            battlefield_to_clear.append(ship_coord)
            $TileMap.set_cell(MAP_LAYER_SHIPS, new_tile, PLAYER_SHIP_TILESET, Vector2i(0, 0))

    # pop spawned ship from original player strategy
    for ship_coord in battlefield_to_clear:
        battlefield_start.erase(ship_coord)

    # check game over
    if len(battlefield_winners) >= SHIPS_TO_WIN:
        print("GAME OVER: YOU WIN")
    elif not battlefield_new and not battlefield_start:
        print("GAME OVER: YOU LOST ALL SHIPS")

    # updated battlefield is the new battlefield 
    battlefield_curr = battlefield_new
