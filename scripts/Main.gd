extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
    $Intro.stop()
    $ButtonStart.visible = false
    $HUD/LabelPhase.visible = false
    $Intro.play("Intro_timeline")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Run when planning phase ends and game starts.
func start_game():
    $HUD/LabelPhase.text = "Attacking..."
    $HUD/LabelPhase.visible = false
    $HUD/StatsContainer.visible = true
    $ButtonStart.text = "New game"
    $GameBoard.start_game()
    $TimeClock.start(1)


# Run when game ends and planning phase starts.
func reset_game():
    $HUD/LabelPhase.text = "Planning phase"
    $HUD/LabelPhase.visible = true
    $HUD/StatsContainer.visible = false
    $ButtonStart.text = "Start"
    $LabelEndGame.text = ""
    $LabelEndGame.visible = false
    $GameBoard.reset_game()
    $TimeClock.stop()


# Run at each turn, so each timer clock.
# Used to update UI
func next_turn():
    var values = $GameBoard.proxy_counters()
    $HUD/StatsContainer/DeadLabel.text = str(values['dead'])
    $HUD/StatsContainer/WinnersLabel.text = str(values['winners'])
    $HUD/StatsContainer/PopulationLabel.text = str(values['population'])+'/'+str($GameBoard.FLEET_SIZE)


# Toggle plan/attack phase, which determines:
# - whether the user can click on the map 
# - whether show the Hero and its fire range
# - change button and label texts
func _on_button_start_pressed():
    var is_plan_phase = $GameBoard.is_plan_phase
    var intro_node = get_node_or_null("Intro")
    if intro_node:
        intro_node.queue_free()
    if is_plan_phase and len($GameBoard.battlefield_start) == 0:
        return  # no ship on the field
    is_plan_phase = not $GameBoard.is_plan_phase
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


# On intro finish
func _on_intro_animation_finished(anim_name):
    $ButtonStart.visible = true
    $HUD/LabelPhase.visible = true
