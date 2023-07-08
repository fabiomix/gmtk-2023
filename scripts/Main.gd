extends Node2D


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
    #$Defender.visible = true
    $GameBoard.start_game()
    $TimeClock.start(1)


# Run when game ends and planning phase starts.
func reset_game():
    $HUD/LabelPhase.text = "Planning phase"
    $ButtonStart.text = "Start"
    #$Defender.visible = false
    $TimeClock.stop()


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
