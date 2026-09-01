extends Area2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var scan_ok_timer:= $ScanOkTimer

signal scan_successfully

var scan_ok = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if scan_ok: 
		animation.play("scan_ok")
	elif Input.is_action_pressed("scan"):
		animation.play("scanning")
	else:
		animation.play("default")


func _on_scan_ok_timer_timeout() -> void:
	scan_ok = false


func _on_game_scan_successfully() -> void:
	scan_ok = true
	scan_ok_timer.start()
