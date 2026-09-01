extends Node2D

@onready var scan_hand:= $ScanHand
@onready var grab_hand:= $GrabHand
@onready var scan_timer:= $ScanTimer
@onready var item_list_node:= $Node

@export var move_velocity: int = 30;
@export var min_time_to_scan: float = 0.2;
@export var max_time_to_scan: float = 0.6;
@export var left_handed: bool = false;

var left_hand : Node2D;
var right_hand : Node2D;

var item_list : Array[Item] = []
var picked_item : Item = null

var scanned_item_list : Array[Item] = []

var obstructed = false;
var scanning_barcode = false;

signal scan_successfully()
signal update_item_list(scanned_item_list: Array[Item])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for item in item_list_node.get_children():
		if item is Item:
			item_list.append(item)
			
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
					item_list.erase(item)
					break
	if event.is_action_released("grab"):
		print("Released")
		if picked_item != null:
			picked_item.drop()
			item_list.append(picked_item)
			picked_item = null
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	scanning_barcode = false;
	
	right_hand.position = get_local_mouse_position()
	if Input.is_action_pressed("move_up"):
		left_hand.position.y -= move_velocity
		if picked_item != null:
			picked_item.position.y -= move_velocity
	if Input.is_action_pressed("move_down"):
		left_hand.position.y += move_velocity
		if picked_item != null:
			picked_item.position.y += move_velocity
	if Input.is_action_pressed("move_left"):
		left_hand.position.x -= move_velocity
		if picked_item != null:
			picked_item.position.x -= move_velocity
	if Input.is_action_pressed("move_right"):
		left_hand.position.x += move_velocity
		if picked_item != null:
			picked_item.position.x += move_velocity
	if Input.is_action_pressed("scan"):
		if picked_item != null and picked_item.scanable and !obstructed:
			scanning_barcode = true
	
	left_hand.position = left_hand.position.clamp(Vector2.ZERO, get_viewport_rect().size)
	if picked_item != null:
		picked_item.position = picked_item.position.clamp(Vector2.ZERO, get_viewport_rect().size)
	
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
