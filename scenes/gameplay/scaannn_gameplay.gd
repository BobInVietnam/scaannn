extends Node2D

@onready var scan_hand:= $ScanHand
@onready var grab_hand:= $GrabHand
@onready var scan_timer:= $ScanTimer
@onready var spawn_timer:= $SpawnTimer
@onready var item_list_node:= $Items
@onready var customer_list_node:= $Customers
@onready var pause_menu:= $PauseMenu

@export var x_move_velocity: int = 10;
@export var y_move_velocity: int = 5;
@export var min_time_to_scan: float = 0.2;
@export var max_time_to_scan: float = 0.6;
@export var left_handed: bool = false;

@export var item_category: Dictionary

var left_hand : Node2D;
var right_hand : Node2D;

var current_customer: Customer = null
var item_list : Array[Item] = []
var picked_item : Item = null
var customer_count : int = 0
var order_completed : int = 0
var total_earned : int = 0

var scanned_item_list : Dictionary = {} # String -> [count, price_tag]
var confirmed_item_list : Array[Item] = []

var obstructed = false;
var scanning_barcode = false;
var scan_success_pause = false;

signal scan_successfully()
signal update_item_list(scanned_item_list: Dictionary)
signal not_enough_item
signal lacking_scan
signal excess_scan
signal order_done
signal update_stats(customer_count: int, order_completed: int, total_earned: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#for item in item_category.keys():
		#var new_item: Node2D = item_category[item].instantiate()
		#new_item.scale = Vector2(3, 3)
		#item_list_node.add_child(new_item)
#
	#for item in item_list_node.get_children():
		#if item is Item:
			#item_list.append(item)
	#item_list.reverse()
	
	#spawn_timer.start(5)
			
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
		_confirm_order()
	if event.is_action_pressed("reset_order"):
		scanned_item_list.clear()
		update_item_list.emit(scanned_item_list)
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		pause_menu.visible = true
		

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
		
func _confirm_order() -> void:
	if current_customer == null:
		return
	# Check for confirmed item
	var temp_dict : Dictionary = {}
	for item in confirmed_item_list:
		if temp_dict.has(item.item_name):
			temp_dict[item.item_name] += 1
		else:
			temp_dict[item.item_name] = 1
			
	for category in current_customer.order.keys():
		if !temp_dict.has(category) or temp_dict[category] <  current_customer.order[category]:
			print("not enough item confirmed")
			not_enough_item.emit()
			return
		if !scanned_item_list.has(category) or scanned_item_list[category][0] < current_customer.order[category]:
			print("lacking scan for some items")
			lacking_scan.emit()
			return
		if scanned_item_list[category][0] > current_customer.order[category]:
			print("Too much scan for some items")
			excess_scan.emit()
			return
	
	# Success: clear things
	print("CLEARED ITEMS\n---------------")
	for item in confirmed_item_list:
		total_earned += item.item_price
		item_list.erase(item)
		print(item.to_string())
		item.queue_free()
	print("---------------")
	customer_count -= 1
	order_completed += 1
	scanned_item_list.clear()
	update_item_list.emit(scanned_item_list)
	order_done.emit()
	update_stats.emit(customer_count, order_completed, total_earned)
	
func _spawn_item(name: String) -> void:
	var new_item: Node2D = item_category[name].instantiate()
	new_item.scale = Vector2(3, 3)
	item_list_node.add_child(new_item)
	item_list.push_front(new_item)
	print("added new item ", new_item.to_string())

func _on_scan_timer_timeout() -> void:
	print("Scan done: item ", picked_item)
	if !scanned_item_list.has(picked_item.item_name):
		scanned_item_list[picked_item.item_name] = [1, picked_item.item_price]
	else:
		scanned_item_list[picked_item.item_name][0] += 1
	scan_successfully.emit()
	update_item_list.emit(scanned_item_list)
	scan_timer.stop()
	scan_success_pause = true

func _on_spawn_timer_timeout() -> void:
	var list = item_category.keys()
	_spawn_item(list[randi_range(0, list.size() - 1)])

func _on_countertop_confirm_area_entered(area: Area2D) -> void:
	var item = area.get_parent()
	confirmed_item_list.append(item)
	print(item.to_string(), " is in confirmed area")

func _on_countertop_confirm_area_exited(area: Area2D) -> void:
	var item = area.get_parent()
	confirmed_item_list.erase(item)
	print(item.to_string(), " exited confirmed area")
	
func _on_customers_customer_order(customer: Customer) -> void:
	current_customer = customer
	if customer != null:
		for item in customer.order.keys():
			for i in range(customer.order[item]):
				_spawn_item(item)
				await get_tree().create_timer(0.5, false).timeout


func _on_pause_menu_unpause() -> void:
	get_tree().paused = false
	pause_menu.visible = false


func _on_customers_new_customer_in() -> void:
	customer_count += 1
	update_stats.emit(customer_count, order_completed, total_earned)
