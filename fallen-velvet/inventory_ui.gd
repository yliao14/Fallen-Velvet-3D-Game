extends CanvasLayer

@onready var slots: Dictionary = {
	"vodka": $SidePanel/VodkaSlot,
	"tomato": $SidePanel/TomatoSlot,
	"lemon": $SidePanel/LemonSlot,
	"pepper": $SidePanel/PepperSlot,
	"celery": $SidePanel/CelerySlot,
}

@onready var photo_slot: TextureRect = $SidePanel/PhotoSlot
@onready var side_panel: Control = $SidePanel

var has_appeared: bool = false
var is_clickable_mode: bool = false


func _ready() -> void:
	add_to_group("inventory_ui")
	
	side_panel.visible = false
	
	for slot in slots.values():
		slot.modulate.a = 0.0
	
	photo_slot.modulate.a = 0.0
	photo_slot.gui_input.connect(_on_photo_input)
	
	GameManager.recipe_found.connect(_on_recipe_found)
	GameManager.item_collected.connect(_on_item_collected)
	GameManager.photo_obtained.connect(_on_photo_obtained) 
	
	# 為每個 slot 加入 mouse 點擊事件
	for item_id in slots.keys():
		var slot = slots[item_id]
		slot.gui_input.connect(_on_slot_input.bind(item_id))


func _on_recipe_found() -> void:
	if has_appeared:
		return
	has_appeared = true
	
	await get_tree().create_timer(0.3).timeout
	
	side_panel.visible = true
	var original_x = side_panel.position.x
	side_panel.position.x += 200
	side_panel.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(side_panel, "position:x", original_x, 0.6)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(side_panel, "modulate:a", 1.0, 0.6)


func _on_item_collected(item_id: String) -> void:
	print("🎒 InventoryUI 收到 item_collected: ", item_id)
	var slot = slots.get(item_id)
	print("   對應 slot: ", slot)
	
	if not slot:
		return
	_animate_slot_unlock(slot)


func _on_photo_obtained() -> void:
	print("🎒 InventoryUI 收到 photo_obtained")
	_animate_slot_unlock(photo_slot)


func _on_photo_clicked() -> void:
	print("📷 點擊底片")


func _animate_slot_unlock(slot: Control) -> void:
	slot.pivot_offset = slot.size / 2.0
	slot.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(slot, "modulate:a", 1.0, 0.4)
	tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	var tween2 = create_tween()
	tween2.tween_property(slot, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# === Cocktail Mixing 模式 ===

# 切換可點擊模式（cocktail_mixer 呼叫）
func set_clickable_mode(enabled: bool) -> void:
	is_clickable_mode = enabled
	
	for item_id in slots.keys():
		var slot = slots[item_id]
		if enabled and GameManager.has_item(item_id):
			slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			slot.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_slot_input(event: InputEvent, item_id: String) -> void:
	if not is_clickable_mode:
		return
	if not GameManager.has_item(item_id):
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_use_ingredient(item_id)

		
func _on_photo_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_photo_clicked()


func _use_ingredient(item_id: String) -> void:
	# 找 cocktail mixer 並通知它加入材料
	var mixer = get_tree().get_first_node_in_group("cocktail_mixer")
	if mixer and mixer.has_method("add_ingredient"):
		mixer.add_ingredient(item_id)
	
	# slot 動畫：縮小淡出
	_animate_slot_use(item_id)


func _animate_slot_use(item_id: String) -> void:
	var slot = slots[item_id]
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(slot, "modulate:a", 0.0, 0.4)
	tween.tween_property(slot, "scale", Vector2(0.5, 0.5), 0.4)
	
	await tween.finished
	
	# 重置 scale 但保持透明（等同空 slot）
	slot.scale = Vector2.ONE
