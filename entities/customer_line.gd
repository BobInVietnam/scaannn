extends Node2D

const MOVE_TIME = 6
const MOVE_DELAY = 1
const LERP_RATE = 1.0
const DISTANCE = 300

@onready var customer_spawn : Marker2D = $CustomerSpawn
@onready var spawn_timer : Timer = $SpawnTimer
@onready var customer_line : Node2D = $CustomerContainer
var empty = true
@export var customer_types : Dictionary

signal customer_order(customer: Customer)

var assigned_x_list : Array = [] # Save from-to coord of customer for moving calculation
var accumulated_t : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_timer.start(5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	accumulated_t += delta
			

func get_customer_line() -> Array[Node]:
	return self.customer_line.get_children()

func _load_customers_position() -> void:
	assigned_x_list = []
	var child_list : Array[Node] = self.customer_line.get_children()
	for i in range(child_list.size()):
		assigned_x_list.append(Vector2(i * DISTANCE, 0))

func _spawn_customer(type: String) -> void:
	var new_customer: Node2D = customer_types[type].instantiate()
	new_customer.position = customer_spawn.position
	new_customer.scale = Vector2(3, 3)
	self.customer_line.add_child(new_customer)
	
	_load_customers_position()
	move(new_customer, assigned_x_list.back(), MOVE_TIME)
	if empty:
		customer_order.emit(customer_line.get_child(0))
		empty = false

func move_first_out() -> void:
	var current_customer = customer_line.get_child(0)
	move(current_customer, Vector2(-1000, 0), MOVE_TIME)
	await get_tree().create_timer(MOVE_TIME).timeout
	print("Removing first")
	assigned_x_list.pop_front()
	var child_to_remove = customer_line.get_child(0)
	customer_line.remove_child(child_to_remove)
	child_to_remove.queue_free()
	_load_customers_position()
	_start_moving()
	var customer = customer_line.get_child(0)
	if customer == null:
		empty = true
	customer_order.emit(customer)


func _start_moving() -> void:
	#update_t = accumulated_t
	for i in range(customer_line.get_children().size()):
		var customer = customer_line.get_child(i) as Node2D
		move_with_delay(customer, assigned_x_list[i], i * MOVE_DELAY, MOVE_TIME)

func move(object: Node2D, des: Vector2, duration: float) -> void:
	var tween = object.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(object, "position", des, duration)
	
func move_with_delay(object: Node2D, des: Vector2, wait: float, duration: float) -> void:
	var tween = object.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(wait)
	tween.tween_property(object, "position", des, duration)

func _on_spawn_timer_timeout() -> void:
	print("spawned test")
	_spawn_customer("test")

func _on_game_order_done() -> void:
	move_first_out()
