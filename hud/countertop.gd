extends Node2D

@onready var item_scanned_label:= $ItemScannedLabel
@onready var price_label:= $PriceLabel
@onready var total_label:= $TotalLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_game_update_item_list(scanned_item_list: Array[Item]) -> void:
	var item_label_list : Array[String] = []
	var price_list : Array[int] = []
	var total_price : int = 0
	for item in scanned_item_list:
		item_label_list.append(item.item_name)
		price_list.append(item.item_price)
		total_price += item.item_price
	item_label_list = item_label_list.slice(-5)
	price_list = price_list.slice(-5)
	
	var name_label_str = ""
	var price_label_str = ""
	
	for name_str in item_label_list:
		name_label_str = name_label_str + name_str + "\n"
	for i in price_list:
		price_label_str = price_label_str + str(i) + " Đ" + "\n"
	item_scanned_label.text = name_label_str
	price_label.text = price_label_str
	total_label.text = "T.Cộng " + str(total_price) + " Đ"
