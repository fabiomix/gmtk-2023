extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Toggle plan/attack phase, which determines
# whether the user can click on the map 
func _on_button_start_pressed():
    var is_plan_phase = not $GameBoard.is_plan_phase
    if is_plan_phase:
        $HUD/LabelPhase.text = "Planning phase"
    else:
        $HUD/LabelPhase.text = "Attacking..."
    print("is_plan_phase " + str(is_plan_phase))
    $GameBoard.is_plan_phase = is_plan_phase
