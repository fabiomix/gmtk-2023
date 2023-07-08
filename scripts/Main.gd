extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Toggle plan/attack phase, which determines:
# - whether the user can click on the map 
# - whether show the Hero and the fire range
# - change button and label texts
func _on_button_start_pressed():
    var is_plan_phase = not $GameBoard.is_plan_phase
    if is_plan_phase:
        $HUD/LabelPhase.text = "Planning phase"
        $GameBoard/FireRange.visible = false
    else:
        $HUD/LabelPhase.text = "Attacking..."
        $GameBoard/FireRange.visible = true
    print("is_plan_phase " + str(is_plan_phase))
    $GameBoard.is_plan_phase = is_plan_phase
