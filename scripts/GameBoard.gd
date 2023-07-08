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
const HERO_SHIP_TILESET = 4
# Number of ships that should reach Earth to win
const SHIPS_TO_WIN = 3
# Fire range, as number of tiles
const FIRE_RANGE_TILE = 3  # maybe 4?
# Number of tile that the Hero can move in one turn
const MAX_HERO_TILE_JUMP = 2

# edit/attack mode
var is_plan_phase = false
# list of player ships coordinates, at start and at runtime
# format: [(5, 2), (3, 4), ...]
var battlefield_start = []
var battlefield_curr = []
var battlefield_winners = []
# position of the Hero
var hero_coord = Vector2i(0, 0)


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
            clear_tileset(selected_tile)
        elif len(battlefield_start) < FLEET_SIZE:
            # add new ship
            print("Ship in " + str(selected_tile))
            battlefield_start.append(selected_tile)
            update_tileset(selected_tile, PLAYER_SHIP_TILESET)
        else:
            print("Max fleet capacity reached")


# InputEventMouseButton position is absolute, not relative to map
# We remove the scene padding and return local Vector2D
func normalize_position(pos : Vector2i):
    pos.x = pos.x - $TileMap.position.x
    pos.y = pos.y - $TileMap.position.y
    return pos


# Ensure that clicked tile is a valid tile.
# Exclude out of map cells and Hero cells (first row)
func get_clicked_tile(click_position : Vector2i):
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


# Switch texture between two tileset
func move_tileset(from_pos : Vector2i, to_pos : Vector2i):
    var source_id = $TileMap.get_cell_source_id(MAP_LAYER_SHIPS, from_pos)
    if not is_tileset_empty(to_pos):
        printerr("COLLISION DETECTED")
    $TileMap.set_cell(MAP_LAYER_SHIPS, from_pos, -1, Vector2i(0, 0))
    $TileMap.set_cell(MAP_LAYER_SHIPS, to_pos, source_id, Vector2i(0, 0))

# Shortcut to empty one tileset
func clear_tileset(from_pos : Vector2i):
    $TileMap.set_cell(MAP_LAYER_SHIPS, from_pos, -1, Vector2i(0, 0))

# Shortcut to set an image on one tileset
func update_tileset(from_pos : Vector2i, source_id : int):
    $TileMap.set_cell(MAP_LAYER_SHIPS, from_pos, source_id, Vector2i(0, 0))

# Shortcut to know if a tileset is empty or has a texture
func is_tileset_empty(from_pos : Vector2i) -> bool:
    var source_id = $TileMap.get_cell_source_id(MAP_LAYER_SHIPS, from_pos)
    return true if source_id == -1 else false


# Run when planning phase ends and game starts.
# Used to clear screen.
func start_game():
    $FireRange.visible = true
    for ship_coord in battlefield_start:
        clear_tileset(ship_coord)  # clear screen
    hero_coord = Vector2i(3, 0)
    update_tileset(hero_coord, HERO_SHIP_TILESET)  # spawn hero


# Run when game ends and planning phase starts.
func reset_game():
    $FireRange.visible = false
    battlefield_curr.append(hero_coord)
    for ship_coord in battlefield_curr:
        clear_tileset(ship_coord)  # clear battlefield
    battlefield_start = []
    battlefield_curr = []
    battlefield_winners = []
    hero_coord = Vector2i(0, 0)


# Run at each turn, so each timer clock.
# Used to move and spawn player ships.
func next_turn():
    var battlefield_new = []
    var battlefield_to_clear = []
    var new_coord = false
    var next_row_index_to_spawn = 32

    # move active ships one-tile-up,
    # clean and re-draw ship
    for ship_coord in battlefield_curr:
        new_coord = ship_coord + Vector2i(0, -1)
        # discard winners, keep other invaders
        if new_coord.y < 0:
            clear_tileset(ship_coord)
            battlefield_winners.append(new_coord)
        else:
            move_tileset(ship_coord, new_coord)
            battlefield_new.append(new_coord)

    # find the next row to spawn (this is embarassing...)
    # min(coord.y for coord in battlefield_start)
    for ship_coord in battlefield_start:
        next_row_index_to_spawn = min(next_row_index_to_spawn, ship_coord.y)

    # spawn new ships
    for ship_coord in battlefield_start:
        if ship_coord.y == next_row_index_to_spawn:
            new_coord = Vector2i(ship_coord.x, MAX_TILE_Y-1)
            battlefield_new.append(new_coord)
            battlefield_to_clear.append(ship_coord)
            update_tileset(new_coord, PLAYER_SHIP_TILESET)

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
    # hero turn
    hero_action()


# Given the invaders and hero positions, think hero next move:
# move over the closest enemy ship if in range
func hero_choose_best_move():
    var closest_target = false
    var new_vector = false

    # find the closest player ship
    for ship_coord in battlefield_curr:
        if not closest_target:
            closest_target = ship_coord
        elif ship_coord.y < closest_target.y:
            closest_target = ship_coord

    # check if out of range, we ignore everything beyond that
    if closest_target and closest_target.y > FIRE_RANGE_TILE:
        closest_target = false

    # check if the Hero see an enemy
    if not closest_target:
        print("Nothing on radar, sir")
        return null
    elif hero_coord.x == closest_target.x:
        print("Targeting " + str(closest_target))
        print("Already in position, ready to fire!")
        return 0
    else:
        print("Targeting " + str(closest_target))
        print("I should move from col %s to %s" % [hero_coord.x, closest_target.x])
    new_vector = min(abs(hero_coord.x - closest_target.x), MAX_HERO_TILE_JUMP)
    return new_vector * -1 if (hero_coord.x > closest_target.x) else new_vector


# Execute the next move of the Hero ship,
# standby, moving or shooting
func hero_action():
    var hero_next_move = hero_choose_best_move()
    if hero_next_move == null:
        pass  # dont know what to do
    elif hero_next_move == 0:
        pass  # [TODO] fire
    else:
        # changing column
        move_tileset(hero_coord, Vector2i(hero_coord.x + hero_next_move, hero_coord.y))
        hero_coord.x = hero_coord.x + hero_next_move
