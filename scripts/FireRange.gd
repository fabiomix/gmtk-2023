extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


# Drawing hero fire range
func _draw():
    draw_circle(Vector2(0, 0), 300, Color.hex(0xbe546033))
