extends Control

@onready var customer_count:= $GridContainer/CustomerCount
@onready var order_done:= $GridContainer/OrderDone
@onready var money_earned:= $GridContainer/MoneyEarned

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_game_update_stats(customer_count: int, order_completed: int, total_earned: int) -> void:
	self.customer_count.text = "X " + str(customer_count) + " đang chờ"
	self.order_done.text = "Hoàn Thành : " + str(order_completed)
	self.money_earned.text = str(total_earned) + " Đ"
