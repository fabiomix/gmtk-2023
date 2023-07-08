extends Node2D

# Fire range, as number of tiles
const FIRE_RANGE_TILE = 3  # maybe 4?
# Number of tile that the Hero can move in one turn
const MAX_HERO_TILE_JUMP = 2


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


func choose_best_move(player_fleet : Array, defender_tile : Vector2i):
    var closest_target = false
    var new_vector = false
    # find the closest player ship
    for ship_vector in player_fleet:
        if not closest_target:
            closest_target = ship_vector
        elif ship_vector.y < closest_target.y:
            closest_target = ship_vector
    # check if out of range, we ignore everything beyond that
    if closest_target and closest_target.y > FIRE_RANGE_TILE:
        closest_target = false
    # check if the Hero see an enemy
    if not closest_target:
        print("Nothing on radar, sir")
        return null
    elif defender_tile.x == closest_target.x:
        print("Targeting " + str(closest_target))
        print("Already in position, ready to fire!")
        return 0
    else:
        print("Targeting " + str(closest_target))
        print("I should move from col %s to %s" % [defender_tile.x, closest_target.x])
    
    new_vector = min(abs(defender_tile.x - closest_target.x), MAX_HERO_TILE_JUMP)
    return new_vector * -1 if (defender_tile.x > closest_target.x) else new_vector
