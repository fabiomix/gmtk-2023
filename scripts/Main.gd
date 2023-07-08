extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Toggle plan/attack phase, which determines:
# - whether the user can click on the map 
# - whether show the Hero and its fire range
# - change button and label texts
func _on_button_start_pressed():
    var is_plan_phase = not $GameBoard.is_plan_phase
    if is_plan_phase:
        $HUD/LabelPhase.text = "Planning phase"
        $GameBoard/FireRange.visible = false
        $GameClock.stop()
    else:
        $HUD/LabelPhase.text = "Attacking..."
        $GameBoard/FireRange.visible = true
        $GameBoard.start_game()
        $GameClock.start(1)
    print("is_plan_phase " + str(is_plan_phase))
    $GameBoard.is_plan_phase = is_plan_phase


func _on_game_clock_timeout():
    $GameBoard.next_turn()
    var player_fleet = $GameBoard.battlefield_curr
    var defender_tile = Vector2i(3, 0)
    $Defender.evaluating_strategies(player_fleet, defender_tile)
