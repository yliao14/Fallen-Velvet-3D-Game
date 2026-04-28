extends CanvasLayer

@onready var quest_label: Label = $QuestLabel


func _ready() -> void:
	print("📜 QuestTracker _ready called")
	
	# 顯示初始任務
	quest_label.text = GameManager.get_current_quest_text()
	
	# 監聽任務變化
	GameManager.quest_stage_changed.connect(_on_quest_changed)
	print("📜 Connected to quest_stage_changed signal")


func _on_quest_changed(_new_stage) -> void:
	var new_text = GameManager.get_current_quest_text()
	print("📜 QuestTracker received quest_stage_changed → ", new_text)
	_animate_quest_change(new_text)


func _animate_quest_change(new_text: String) -> void:
	# 平滑切換：淡出 → 換字 → 淡入
	var tween = create_tween()
	tween.tween_property(quest_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): quest_label.text = new_text)
	tween.tween_property(quest_label, "modulate:a", 1.0, 0.4)
