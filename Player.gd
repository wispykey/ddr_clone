extends Node2D

signal hit
signal miss

var left_arrows: Array = []
var right_arrows: Array = []
var down_arrows: Array = []

var LEFT_HITBOX_X: float
var DOWN_HITBOX_X: float
var RIGHT_HITBOX_X: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LEFT_HITBOX_X = get_node("LeftInputHitbox/CollisionShape2D").position.x
	DOWN_HITBOX_X = get_node("DownInputHitbox/CollisionShape2D").position.x
	RIGHT_HITBOX_X = get_node("RightInputHitbox/CollisionShape2D").position.x

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("input_left") && !left_arrows.is_empty():
		var oldest_left_arrow = left_arrows.pop_front()
		hit.emit(oldest_left_arrow)
	elif Input.is_action_just_pressed("input_right") && !right_arrows.is_empty():
		var oldest_right_arrow = right_arrows.pop_front()
		hit.emit(oldest_right_arrow)
	elif Input.is_action_just_pressed("input_down") && !down_arrows.is_empty():
		var oldest_down_arrow = down_arrows.pop_front()
		hit.emit(oldest_down_arrow)
		
	'''
	# PREVIOUS APPROACH (INCONSISTENT RESULTS)
	# Allow some frames to pass before re-disabling CollisionShapes
	if delta_sum > hit_window:
		left_collision_shape.set_deferred("disabled", true)
		right_collision_shape.set_deferred("disabled", true)
		down_collision_shape.set_deferred("disabled", true)
		delta_sum = 0
	else: 
		delta_sum += delta
	'''
		

func _on_left_input_hitbox_body_entered(body: Node2D) -> void:
	left_arrows.append(body)
	body.deleted.connect(_on_arrow_deleted)

func _on_right_input_hitbox_body_entered(body: Node2D) -> void:
	right_arrows.append(body)
	body.deleted.connect(_on_arrow_deleted)

func _on_down_input_hitbox_body_entered(body: Node2D) -> void:
	down_arrows.append(body)
	body.deleted.connect(_on_arrow_deleted)
	
func _on_arrow_deleted(x: float):
	if x == LEFT_HITBOX_X:
		left_arrows.pop_front()
	elif x == DOWN_HITBOX_X:
		down_arrows.pop_front()
	else:
		right_arrows.pop_front()
	miss.emit()
