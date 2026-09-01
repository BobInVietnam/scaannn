extends Node2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var covering_hitbox: Area2D = $CoveringHitbox

signal obstruction(obstructed: bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if  Input.is_action_pressed("grab"):
		animation.play("grab_empty")
	else:
		animation.play("default")
