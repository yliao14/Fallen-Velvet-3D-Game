extends Node3D

@export var slide_distance: float = 0.7    # 板子右移多遠
@export var slide_duration: float = 1.5    # 動畫時間


func _ready() -> void:
	# 監聽板子開啟事件
	GameManager.panel_opened.connect(_on_panel_open)


func _on_panel_open() -> void:
	# 板子右移
	var tween = create_tween()
	tween.tween_property(self, "position:x", position.x + slide_distance, slide_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 加點振動感
	var shake = create_tween()
	shake.tween_property(self, "position:y", position.y + 0.02, 0.1)
	shake.tween_property(self, "position:y", position.y - 0.02, 0.1)
	shake.tween_property(self, "position:y", position.y, 0.1)
