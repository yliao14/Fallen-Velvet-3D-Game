extends Control

@onready var start_button: Button = $StartButton

# Hover 動畫設定
@export var hover_scale: float = 1.1
@export var hover_duration: float = 0.15

func _ready() -> void:
	# 連結 button 事件
	start_button.pressed.connect(_on_start_button_pressed)
	start_button.mouse_entered.connect(_on_button_hover)
	start_button.mouse_exited.connect(_on_button_unhover)
	
	# 設定 pivot 在 button 中心，scale 才會從中間放大
	start_button.pivot_offset = start_button.size / 2.0


func _on_start_button_pressed() -> void:
	# 防止重複點擊
	start_button.disabled = true
	
	# 按下時有個小縮放反饋
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.08)
	tween.tween_callback(_change_to_invitation_scene)


func _change_to_invitation_scene() -> void:
	# 整個畫面淡出後切場景
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://invitation_letter.tscn")
	)


func _on_button_hover() -> void:
	var tween = create_tween()
	tween.tween_property(
		start_button, 
		"scale", 
		Vector2(hover_scale, hover_scale), 
		hover_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_button_unhover() -> void:
	var tween = create_tween()
	tween.tween_property(
		start_button, 
		"scale", 
		Vector2(1.0, 1.0), 
		hover_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# 讓玩家按 Enter 或 Space 也能 start
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not start_button.disabled:
		_on_start_button_pressed()
