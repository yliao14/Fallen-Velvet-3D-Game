extends StaticBody3D

@export var item_id: String = "rye_whiskey"
@export var pour_color: Color = Color(0.6, 0.3, 0.1, 0.8)
@export var pour_duration: float = 1.5

# 在 Inspector 把 FBX 裡的酒瓶 MeshInstance3D 拖進來
@export var bottle_mesh: MeshInstance3D
# 在 Inspector 把杯子節點拖進來
@export var glass_target: Node3D

var _is_pouring: bool = false
var _origin_position: Vector3
var _origin_rotation: Vector3

signal pour_finished(item_id: String, color: Color)

func _ready() -> void:
	if bottle_mesh:
		_origin_position = bottle_mesh.global_position
		_origin_rotation = bottle_mesh.rotation_degrees

# Player.gd 的 raycast 打到這裡，呼叫這個
func interact() -> void:
	if _is_pouring:
		return
	_pour()

func _pour() -> void:
	if not bottle_mesh or not glass_target:
		push_error("BottlePickup: bottle_mesh 或 glass_target 沒有設定")
		return

	_is_pouring = true

	# Step 1：酒瓶飄到杯子上方
	var above_glass = glass_target.global_position + Vector3(0, 0.5, 0)
	var tween1 = create_tween()
	tween1.set_parallel(true)
	tween1.tween_property(bottle_mesh, "global_position", above_glass, 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween1.finished

	# Step 2：傾倒
	var tween2 = create_tween()
	tween2.tween_property(bottle_mesh, "rotation_degrees:z", 110.0, 0.4)\
		.set_ease(Tween.EASE_OUT)
	await tween2.finished

	# Step 3：等待倒酒時間
	await get_tree().create_timer(pour_duration).timeout

	# Step 4：回正
	var tween3 = create_tween()
	tween3.tween_property(bottle_mesh, "rotation_degrees:z", _origin_rotation.z, 0.3)
	await tween3.finished

	# Step 5：回原位
	var tween4 = create_tween()
	tween4.set_parallel(true)
	tween4.tween_property(bottle_mesh, "global_position", _origin_position, 0.5)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween4.finished

	_is_pouring = false
	pour_finished.emit(item_id, pour_color)
