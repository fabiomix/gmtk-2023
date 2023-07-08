extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Detect user-clicked tile
func _input(event):
	if event is InputEventMouseButton:
		print(event.position)
		print($TileMap.local_to_map(event.position))
