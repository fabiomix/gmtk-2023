extends Node2D

# TileMap doesnt have borders, set max size
const MAX_TILE_X = 7
const MAX_TILE_Y = 10
# Number of ships for the player
const FLEET_SIZE = 7
# Aliases for TileMap and TileSet resource ids
# [FIXME] maybe use @onready?
const MAP_LAYER_SHIPS = 1
const PLAYER_SHIP_TILESET = 6
const HERO_SHIP_TILESET = 4
const LASER_TILESET = 7
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
var battlefield_lasers = []
var battlefield_dead = []
# position of the Hero
var hero_coord = Vector2i(-5, -5)
# track already spawned rows
var next_row_index_to_spawn = 0
# row index that have a starting ship,
# used to ensure max one ship per line
var line_constraint = []


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
            pass  # print("Not in plan phase")
        elif not selected_tile:
            pass  # print("Invalid tile click")
        elif selected_tile in battlefield_start:
            # there is already a ship here, remove it
            print("Removing ship in " + str(selected_tile))
            battlefield_start.erase(selected_tile)
            line_constraint.erase(selected_tile.y)
            clear_tileset(selected_tile)
        elif selected_tile.y in line_constraint:
            pass  # One ship already on this row
        elif len(battlefield_start) < FLEET_SIZE:
            # add new ship
            print("Ship in " + str(selected_tile))
            battlefield_start.append(selected_tile)
            line_constraint.append(selected_tile.y)
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


# Check tile for explosions, then clear the collision cell
func detect_collisions():
    var explosions = []
    for vctr in battlefield_lasers:
        if vctr in battlefield_curr:
            explosions.append(vctr)
    for vctr in explosions:
        if battlefield_lasers.count(vctr) > 1:
            print("DETECTED DUPLICATE " + str(vctr) + "battlefield_lasers")
        if battlefield_curr.count(vctr) > 1:
            print("DETECTED DUPLICATE " + str(vctr) + "battlefield_curr")
        clear_tileset(vctr)
        battlefield_lasers.erase(vctr)
        battlefield_curr.erase(vctr)
        battlefield_dead.append(vctr)
        $RadioNoise.play()
        print("Explosion in " + str(vctr))
    printt("battlefield", battlefield_curr, "lasers", battlefield_lasers)


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
            elif vctr in battlefield_lasers:
                update_tileset(vctr, LASER_TILESET)
            elif vctr in battlefield_curr:
                update_tileset(vctr, PLAYER_SHIP_TILESET)
            else:
                clear_tileset(vctr)

# Run when planning phase ends and game starts.
# Used to clear screen.
func start_game():
    $FireRange.visible = true
    hero_coord = Vector2i(3, 0)  # spawn hero
    battlefield_winners = []
    battlefield_dead = []
    battlefield_lasers = []
    next_row_index_to_spawn = 0
    redraw_battlefield()


# Run when game ends and planning phase starts.
func reset_game():
    $FireRange.visible = false
    hero_coord = Vector2i(-5, -5)
    battlefield_start = []
    battlefield_curr = []
    battlefield_winners = []
    battlefield_dead = []
    battlefield_lasers = []
    line_constraint = []
    redraw_battlefield()


# Run at each turn, so each timer clock.
# Used to move and spawn player ships.
func next_turn():
    invaders_action()
    detect_collisions()
    laser_action()
    detect_collisions()
    hero_action()
    detect_collisions()
    invaders_spawn()
    invaders_game_over()
    redraw_battlefield()


# Move active ships one-tile-up
func invaders_action():
    var battlefield_new = []
    var destination = false

    for vctr in battlefield_curr:
        destination = vctr + Vector2i(0, -1)
        if destination.y < 0:
            # out of map, add to winners and dont readd to battlefield
            battlefield_winners.append(destination)
            print(str(len(battlefield_winners)) + " escaped")
        else:
            # move forward other invaders
            battlefield_new.append(destination)
    battlefield_curr = battlefield_new


# Move laser one-tile-down
func laser_action():
    var battlefield_new = []
    var destination = false

    for vctr in battlefield_lasers:
        destination = vctr + Vector2i(0, 1)
        if destination.y > FIRE_RANGE_TILE:
            continue  # laser out of range, dont readd
        # laser is still valid, move forward for next turn
        battlefield_new.append(destination)
    battlefield_lasers = battlefield_new


# Check for new player ships to pop from strategy
# and spawn into the battlefield
func invaders_spawn():
    var battlefield_new = battlefield_curr
    var battlefield_to_clear = []
    var destination = false

    # spawn new ships
    for vctr in battlefield_start:
        if vctr.y == next_row_index_to_spawn:
            destination = Vector2i(vctr.x, MAX_TILE_Y-1)
            battlefield_new.append(destination)
            battlefield_to_clear.append(vctr)

    # pop spawned ship from original player strategy
    for vctr in battlefield_to_clear:
        battlefield_start.erase(vctr)

    # updated battlefield is the new battlefield
    battlefield_curr = battlefield_new
    next_row_index_to_spawn += 1


# check game over conditions
func invaders_game_over():
    if len(battlefield_winners) >= SHIPS_TO_WIN:
        pass  # print("GAME OVER: YOU WIN")
    elif not battlefield_curr and not battlefield_start:
        pass  # print("GAME OVER: YOU LOST ALL SHIPS")


# Given the invaders and hero positions, think hero next move:
# move over the closest enemy ship if in range
func hero_choose_best_move():
    var closest_target = false
    var new_vector = false
    var shots_x = []
    
    for coord in battlefield_lasers:
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
        return null  # Nothing on radar, sir
    elif hero_coord.x == closest_target.x:
        return 0  # already in position, ready to fire

    # hero should move, max 2 tiles
    new_vector = min(abs(hero_coord.x - closest_target.x), MAX_HERO_TILE_JUMP)
    return new_vector * -1 if (hero_coord.x > closest_target.x) else new_vector


# Shoot the invaders in my trajectory,
# draw laser if tile is empty, otherwise collision and explosion,
# which clear the tile, remove shot and mark my ship as dead
func hero_fire():
    var vctr = Vector2i(hero_coord.x, 1)
    battlefield_lasers.append(vctr)
    print("Fired in " + str(vctr))
    if not is_tileset_empty(vctr):
        # cell is not empty, invader found! insta-kill
        print("Instant kill in " + str(vctr))


# Execute the next move of the Hero ship,
# standby, moving or shooting
func hero_action():
    var hero_next_move = hero_choose_best_move()
    if hero_next_move == null:
        return  # dont know what to do
    # changing column
    hero_coord.x = hero_coord.x + hero_next_move
    # if you jumped only one tile, you can fire in the same turn
    if abs(hero_next_move) < 2:
        hero_fire()


# [DEBUG] print invasion status and game over conditions
func debug_stats():
    printt("winners", battlefield_winners, "dead", battlefield_dead)


# Collect statistics for the UI
func proxy_counters():
    return {
        'dead': len(battlefield_dead),
        'winners': len(battlefield_winners),
        'population': len(battlefield_curr) + len(battlefield_start)
    }
