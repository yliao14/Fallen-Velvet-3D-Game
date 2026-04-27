extends CanvasLayer

@onready var slots: Array[Label] = [
	$PuzzleContainer/Slot_0,
	$PuzzleContainer/Slot_1,
	$PuzzleContainer/Slot_2,
	$PuzzleContainer/Slot_3,
	$PuzzleContainer/Slot_4,
	$PuzzleContainer/Slot_5,
	$PuzzleContainer/Slot_6,
	$PuzzleContainer/Slot_7,
]

@onready var puzzle_container: HBoxContainer = $PuzzleContainer


func _ready() -> void:
	visible = false
	
	# 所有 slot 預設顯示底線
	for slot in slots:
		slot.text = "_"
		slot.modulate = Color(1, 1, 1, 0.4)  # 半透明，代表還沒填
	
	# 監聽 GameManager 事件
	GameManager.photo_obtained.connect(_on_photo_obtained)
	GameManager.letter_collected.connect(_on_letter_collected)
	GameManager.puzzle_completed.connect(_on_puzzle_completed)


# 拿到底片 → 拼字 UI 浮現
func _on_photo_obtained() -> void:
	visible = true
	puzzle_container.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(puzzle_container, "modulate:a", 1.0, 0.8)


# 撿到字母 → 對應 slot 填入
func _on_letter_collected(letter_id: String) -> void:
	# letter_id 格式: "U_0", "P_1" 等
	var parts = letter_id.split("_")
	var letter_char = parts[0]
	var index = int(parts[1])
	
	if index >= 0 and index < slots.size():
		_animate_slot_fill(slots[index], letter_char)


# Slot 填字動畫：從小變大 + 淡入
func _animate_slot_fill(slot: Label, letter: String) -> void:
	slot.pivot_offset = slot.size / 2.0
	
	# 設定文字後從小放大
	slot.text = letter
	slot.scale = Vector2(0.3, 0.3)
	slot.modulate = Color(1, 1, 1, 0)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(slot, "modulate", Color.WHITE, 0.5)
	tween.tween_property(slot, "scale", Vector2(1.3, 1.3), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# 縮回正常大小
	var tween2 = create_tween()
	tween2.tween_property(slot, "scale", Vector2.ONE, 0.2)


# 全拼完 → 跑燈高亮（從左到右每個字母依序閃光）
func _on_puzzle_completed() -> void:
	for i in range(slots.size()):
		var slot = slots[i]
		await get_tree().create_timer(0.1).timeout
		
		var tween = create_tween()
		tween.tween_property(slot, "modulate", Color(1.5, 1.3, 0.8), 0.3)
		tween.tween_property(slot, "modulate", Color.WHITE, 0.3)
