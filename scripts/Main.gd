extends Node2D

# Size of a single tile, in pixel
const  TILE_PIXEL_SIZE = 64


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Run when planning phase ends and game starts.
func start_game():
    $HUD/LabelPhase.text = "Attacking..."
    $ButtonStart.text = "New game"
    $Defender.visible = true
    $GameBoard.start_game()
    $TimeClock.start(1)


# Run when game ends and planning phase starts.
func reset_game():
    $HUD/LabelPhase.text = "Planning phase"
    $ButtonStart.text = "Start"
    $Defender.visible = false
    $TimeClock.stop()


# Run at each turn, so each timer clock.
# Used to move the Hero ship.
func next_turn():
    var battlefield = $GameBoard.battlefield_curr
    var defender_tile = $GameBoard.get_clicked_tile($Defender.position, true)
    var defender_shift = $Defender.choose_best_move(battlefield, defender_tile)
    if defender_shift == null:
        pass
    elif defender_shift == 0:
        pass
    else:
        set_defender_position(defender_shift)


# Toggle plan/attack phase, which determines:
# - whether the user can click on the map 
# - whether show the Hero and its fire range
# - change button and label texts
func _on_button_start_pressed():
    var is_plan_phase = not $GameBoard.is_plan_phase
    if is_plan_phase:
        reset_game()
    else:
        start_game()
    print("is_plan_phase " + str(is_plan_phase))
    $GameBoard.is_plan_phase = is_plan_phase


# Clock timeout, used for:
# - move player ships
# - move Hero ship
func _on_game_clock_timeout():
    $GameBoard.next_turn()
    next_turn()


# Move Hero ship by "shifting" number of tiles.
# Can be negative to go left. Convert tile in pixels.
func set_defender_position(shifting : int):
    $Defender.position.x += (shifting * TILE_PIXEL_SIZE)
