extends Node2D
class_name Item

const MAX_HEIGHT = 50;

@onready var animation:= $AnimatedSprite2D
@onready var scan_hitbox:= $ScanHitbox
@onready var pickup_hitbox:= $PickUpHitbox

var grabable = false;
var scanable = false;
@export var picked_up = false;
var current_height = 0;
var velocity = Vector2(0, 0);

const GRAVITY = Vector2(0, 20);

# Stats of item
@export var item_name: String = "placeholder_lays"
@export var item_price: int = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scan_hitbox.monitoring = false;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_height > 0 and !picked_up:
		velocity += GRAVITY
	
	position += velocity;
	current_height -= velocity.y
	
	# TEXTURE PROCESSING
	if picked_up:
		animation.play("picked_up")
	else:
		animation.play("default")
		
	_setShader(true) if grabable else _setShader(false)
		
		
func pick_up() -> void:
	picked_up = true;
	scan_hitbox.monitoring = true;
	
func drop() -> void:
	picked_up = false;
	scan_hitbox.monitoring = false;
	scanable = false;
	
func _setShader(isOn: bool):
	var shader_material = animation.material as ShaderMaterial
	
	if shader_material:
		shader_material.set_shader_parameter("flash_modifier", 0.3 if isOn else 0.0)

#func _on_pick_up_hitbox_area_entered(area: Area2D) -> void:
	#print("Item pickable")
	#grabable = true;
	#if !picked_up:
		#_setShader(true)
	#else:
		#_setShader(false)
#
#func _on_pick_up_hitbox_area_exited(area: Area2D) -> void:
	#print("Item not pickable")
	#grabable = false;
	#_setShader(false)
	#
func _on_scan_hitbox_area_entered(area: Area2D) -> void:
	print("Scanable")
	scanable = true;

func _on_scan_hitbox_area_exited(area: Area2D) -> void:
	print("No longer scanable")
	scanable = false;
