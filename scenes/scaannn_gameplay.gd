extends Node2D

@onready var scan_hand:= $ScanHand
@onready var grab_hand:= $GrabHand
@onready var scan_timer:= $ScanTimer
@onready var spawn_timer:= $SpawnTimer
@onready var item_list_node:= $Node

@export var x_move_velocity: int = 30;
@export var y_move_velocity: int = 15;
@export var min_time_to_scan: float = 0.2;
@export var max_time_to_scan: float = 0.6;
@export var left_handed: bool = false;

@export var item_category: Array[PackedScene]

var left_hand : Node2D;
var right_hand : Node2D;

var item_list : Array[Item] = []
var picked_item : Item = null

var scanned_item_list : Array[Item] = []

var obstructed = false;
var scanning_barcode = false;
var scan_success_pause = false;

signal scan_successfully()
signal update_item_list(scanned_item_list: Array[Item])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for item in item_category:
		var new_item: Node2D = item.instantiate()
		new_item.scale = Vector2(3, 3)
		item_list_node.add_child(new_item)

	for item in item_list_node.get_children():
		if item is Item:
			item_list.append(item)
	item_list.reverse()
	
	spawn_timer.start(5)
			
	if left_handed :
		left_hand = scan_hand
		right_hand = grab_hand
	else:
		left_hand = grab_hand
		right_hand = scan_hand

func _input(event):
	if event.is_action_pressed("grab"):
		print("Grabbing")
		if picked_item == null:
			for item in item_list:
				if item.grabable:
					print("Grabbed ", item.to_string())
					item.pick_up()
					picked_item = item
					picked_item.move_to_front()
					item_list.erase(item)
					grab_hand.pickup_hitbox.monitoring = false
					if grab_hand.covering_hitbox.overlaps_area(item.scan_hitbox):
						print("Obstructed!")
						obstructed = true;
					break
	if event.is_action_released("grab"):
		print("Released")
		if picked_item != null:
			picked_item.drop()
			item_list.push_front(picked_item)
			picked_item = null
			grab_hand.pickup_hitbox.monitoring = true
			obstructed = false;
	if event.is_action_released("scan"):
		scan_success_pause = false
	if event.is_action_pressed("confirm_order"):
		print("CLEARED ITEMS\n---------------")
		for item in scanned_item_list:
			item_list.erase(item)
			print(item.to_string())
			item.queue_free()
		print("---------------")
		scanned_item_list.clear()
		update_item_list.emit(scanned_item_list)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	scanning_barcode = false;
	
	# ITEM LIST GRABABILITY PROCESSOR (probably a performance chokepoint)
	for i in item_list.size():
		if grab_hand.pickup_hitbox.overlaps_area(item_list[i].pickup_hitbox):
			print(item_list[i].to_string(), " is grabable")
			item_list[i].grabable = true
			for j in range(i + 1, item_list.size()):
				item_list[j].grabable = false
			break
		else:
			item_list[i].grabable = false
	
	# INPUT PROCESSING SECTION
	right_hand.position = get_local_mouse_position()
	
	var velocity = Vector2(0, 0)
	var lhp = left_hand.position
	var viewport_size = get_viewport_rect().size
	if Input.is_action_pressed("move_up"):
		velocity.y -= y_move_velocity if lhp.y - y_move_velocity >= 0 else lhp.y
	if Input.is_action_pressed("move_down"):
		velocity.y += y_move_velocity if lhp.y + y_move_velocity <= viewport_size.y else viewport_size.y - lhp.y 
	if Input.is_action_pressed("move_left"):
		velocity.x -= x_move_velocity if lhp.x - x_move_velocity >= 0 else lhp.x
	if Input.is_action_pressed("move_right"):
		velocity.x += x_move_velocity if lhp.x + x_move_velocity <= viewport_size.x else viewport_size.x - lhp.x 

	if Input.is_action_pressed("scan"):
		if picked_item != null and picked_item.scanable and !obstructed and !scan_success_pause:
			scanning_barcode = true
	
	left_hand.position += velocity
	if picked_item != null:
		picked_item.position += velocity
	
	# SCANNING LOGIC
	if scanning_barcode:
		if scan_timer.is_stopped():
			scan_timer.start(randf_range(min_time_to_scan, max_time_to_scan))
	else:
		scan_timer.stop()

func _on_scan_timer_timeout() -> void:
	print("Scan done: item ", picked_item)
	scanned_item_list.append(picked_item)
	scan_successfully.emit()
	update_item_list.emit(scanned_item_list)
	scan_timer.stop()
	scan_success_pause = true

func _on_spawn_timer_timeout() -> void:
	var new_item: Node2D = item_category[randi_range(0, item_category.size() - 1)].instantiate()
	new_item.scale = Vector2(3, 3)
	item_list_node.add_child(new_item)
	item_list.append(new_item)
	print("added new item ", new_item.to_string())
