extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var cutscene_image: TextureRect = $CutsceneImage
@onready var cutscene_label: Label = $CutsceneLabel

var player: Node = null


func _ready() -> void:
	add_to_group("cutscene_ui")
	visible = false
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


# 公開 API：播放一段 cutscene
# image: 要顯示的 Texture
# title: 螢幕下方文字（可選）
# duration: 凝視時間
func play_cutscene(image: Texture2D, title: String = "", duration: float = 4.0) -> void:
	visible = true
	
	# 設定內容
	cutscene_image.texture = image
	cutscene_label.text = title
	
	# 通知 player 進 UI 模式
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(true)
	
	# 進場：背景全黑，圖+字慢慢浮現
	background.modulate.a = 0.0
	cutscene_image.modulate.a = 0.0
	cutscene_image.scale = Vector2(0.85, 0.85)
	cutscene_image.pivot_offset = cutscene_image.size / 2.0
	cutscene_label.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(background, "modulate:a", 1.0, 0.6)
	tween.tween_property(cutscene_image, "modulate:a", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(cutscene_image, "scale", Vector2.ONE, 1.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(cutscene_label, "modulate:a", 1.0, 1.5).set_delay(0.6)
	await tween.finished
	
	# 凝視
	await get_tree().create_timer(duration).timeout
	
	# 淡出
	var fade = create_tween().set_parallel(true)
	fade.tween_property(background, "modulate:a", 0.0, 1.0)
	fade.tween_property(cutscene_image, "modulate:a", 0.0, 1.0)
	fade.tween_property(cutscene_label, "modulate:a", 0.0, 1.0)
	await fade.finished
	
	visible = false
	
	# 釋放 player
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(false)
