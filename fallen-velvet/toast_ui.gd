extends CanvasLayer

@onready var toast_label: Label = $ToastLabel

# 預設停留時間
@export var default_duration: float = 2.0
@export var fade_in_duration: float = 0.4
@export var fade_out_duration: float = 0.6


func _ready() -> void:
	add_to_group("toast_ui")
	visible = false
	toast_label.modulate.a = 0.0


# ⭐ 公開 API：給其他 script 呼叫
func show_toast(message: String, duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration
	
	toast_label.text = message
	visible = true
	
	# 淡入 → 停留 → 淡出
	toast_label.modulate.a = 0.0
	toast_label.scale = Vector2(0.85, 0.85)
	toast_label.pivot_offset = toast_label.size / 2.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(toast_label, "modulate:a", 1.0, fade_in_duration)
	tween.tween_property(toast_label, "scale", Vector2.ONE, fade_in_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	await get_tree().create_timer(duration).timeout
	
	var fade_out = create_tween()
	fade_out.tween_property(toast_label, "modulate:a", 0.0, fade_out_duration)
	await fade_out.finished
	
	visible = false


# 大字版（給「Level 1 cleared」這種用）
func show_big_toast(message: String, duration: float = 3.0) -> void:
	# 暫時把字型放大
	var original_size = toast_label.get_theme_font_size("font_size")
	toast_label.add_theme_font_size_override("font_size", 80)
	
	await show_toast(message, duration)
	
	# 恢復原大小
	toast_label.add_theme_font_size_override("font_size", original_size)
