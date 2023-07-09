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
const FIRE_RANGE_TILE = 4  # maybe 3?
# Number of tile that the Hero can move in one turn
const MAX_HERO_TILE_JUMP = 2

# edit/attack mode
var is_plan_phase = false
# list of player ships coordinates, format: [(5, 2), (3, 4), ...]
# at start, runtime, shots and out of map
var battlefield_start = []
var battlefield_curr = []
var battlefield_winners = []
var battlefield_shots = []
var battlefield_dead = []
# position of the Hero
var hero_coord = Vector2i(-5, -5)


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
    var destination_id = $TileMap.get_cell_source_id(MAP_LAYER_SHIPS, to_pos)
    if destination_id == HERO_SHIP_TILESET:
        source_id = destination_id  # on collision, hero wins
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

# Shortcut to repaint the battlefield
func redraw_battlefield():
    var vctr = false
    if is_plan_phase:
        return
    for row in range(0, MAX_TILE_X):
        for col in range(0, MAX_TILE_Y):
            vctr = Vector2i(row, col)
            if vctr == hero_coord:
                update_tileset(vctr, HERO_SHIP_TILESET)
            elif vctr in battlefield_shots:
                update_tileset(vctr, HERO_SHIP_TILESET)
            elif vctr in battlefield_curr:
                update_tileset(vctr, PLAYER_SHIP_TILESET)
            else:
                clear_tileset(vctr)

# Run when planning phase ends and game starts.
# Used to clear screen.
func start_game():
    $FireRange.visible = true
    hero_coord = Vector2i(3, 0)  # spawn hero
    redraw_battlefield()


# Run when game ends and planning phase starts.
func reset_game():
    $FireRange.visible = false
    battlefield_start = []
    battlefield_curr = []
    battlefield_winners = []
    battlefield_dead = []
    battlefield_shots = []
    hero_coord = Vector2i(-5, -5)
    redraw_battlefield()


# Run at each turn, so each timer clock.
# Used to move and spawn player ships.
func next_turn():
    var battlefield_new = []
    var battlefield_to_clear = []
    var battlefield_new_shots = []
    var destination = false
    var next_row_index_to_spawn = 32

    # move active ships one-tile-up,
    # clean and re-draw ship
    for ship_coord in battlefield_curr:
        destination = ship_coord + Vector2i(0, -1)
        if destination.y < 0:
            # discard winners, out of map
            battlefield_winners.append(destination)
        elif not is_tileset_empty(destination):
            # check collisions with laser, record kill
            battlefield_dead.append(ship_coord)
            battlefield_shots.erase(destination)
        else:
            # keep other invaders, move them forward
            battlefield_new.append(destination)

    # move shots one-tile-down
    for vctr in battlefield_shots:
        destination = vctr + Vector2i(0, 1)
        if not is_tileset_empty(destination):
            # collision, remove laser and ship
            battlefield_dead.append(destination)
            battlefield_new.erase(destination)
        elif destination.y > FIRE_RANGE_TILE:
            # laser out of range
            pass
        else:
            # laser is still valid, keep it for next turn
            battlefield_new_shots.append(destination)

    # find the next row to spawn (this is embarassing...)
    # min(coord.y for coord in battlefield_start)
    for ship_coord in battlefield_start:
        next_row_index_to_spawn = min(next_row_index_to_spawn, ship_coord.y)

    # spawn new ships
    for ship_coord in battlefield_start:
        if ship_coord.y == next_row_index_to_spawn:
            destination = Vector2i(ship_coord.x, MAX_TILE_Y-1)
            battlefield_new.append(destination)
            battlefield_to_clear.append(ship_coord)

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
    battlefield_shots = battlefield_new_shots
    # hero turn
    hero_action()
    # refresh screen
    redraw_battlefield()


# Given the invaders and hero positions, think hero next move:
# move over the closest enemy ship if in range
func hero_choose_best_move():
    var closest_target = false
    var new_vector = false
    var shots_x = []
    
    for coord in battlefield_shots:
        shots_x.append(coord.x)

    # find the closest player ship
    for ship_coord in battlefield_curr:
        if ship_coord.x in shots_x:
            pass
        elif not closest_target:
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


# Shoot the invaders in my trajectory,
# draw laser if tile is empty, otherwise collision and explosion,
# which clear the tile, remove shot and mark my ship as dead
func hero_fire():
    var vctr = Vector2i(hero_coord.x, 1)
    if is_tileset_empty(vctr):
        # draw laser in empty cell
        battlefield_shots.append(vctr)
    else:
        # cell is not empty, invader found! autokill
        battlefield_curr.erase(vctr)
        battlefield_dead.append(vctr)


# Execute the next move of the Hero ship,
# standby, moving or shooting
func hero_action():
    var hero_next_move = hero_choose_best_move()
    if hero_next_move == null:
        pass  # dont know what to do
    elif hero_next_move == 0:
        hero_fire()  # in position, ready to fire
    else:
        # changing column
        hero_coord.x = hero_coord.x + hero_next_move
