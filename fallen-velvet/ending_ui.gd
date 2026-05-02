extends CanvasLayer

# 必須在 scene 裡有的節點
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var developing_effect: ColorRect = $DevelopingEffect
@onready var photo_reveal: TextureRect = $PhotoReveal
@onready var truth_label: Label = $TruthLabel
@onready var end_label: Label = $EndLabel

# 新增節點 (請在 scene 裡建立)
@onready var developer_image: TextureRect = $DeveloperImage   # 顯影液瓶子，畫面中央偏左
@onready var photo_image: TextureRect = $PhotoImage           # 未沖洗的照片，畫面中央偏右
@onready var subtitle_label: Label = $SubtitleLabel           # "You never left this bar." 副標
@onready var final_overlay: ColorRect = $FinalOverlay         # 最後的全黑覆蓋層
@onready var restart_button: Button = $RestartButton
@onready var end_button: Button = $EndButton

var player: Node = null


func _ready() -> void:
	add_to_group("ending_ui")
	visible = false
	
	# 初始化所有元素為透明
	dark_overlay.color = Color(0, 0, 0, 0)
	developing_effect.color = Color(0.6, 0.05, 0.05, 0)
	photo_reveal.modulate.a = 0.0
	truth_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	end_label.modulate.a = 0.0
	developer_image.modulate.a = 0.0
	photo_image.modulate.a = 0.0
	final_overlay.color = Color(0, 0, 0, 0)
	restart_button.modulate.a = 0.0
	end_button.modulate.a = 0.0
	restart_button.visible = false
	end_button.visible = false
	
	# 連按鈕訊號
	restart_button.pressed.connect(_on_restart_pressed)
	end_button.pressed.connect(_on_end_pressed)
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


func start_developing() -> void:
	visible = true
	
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	await _play_sequence()


func _play_sequence() -> void:
	# 1: 全暗
	var blackout = create_tween()
	blackout.tween_property(dark_overlay, "color:a", 1.0, 2.0)
	await blackout.finished
	
	await get_tree().create_timer(0.5).timeout
	
	# 2: 顯影液 + 照片並排出現在中央
	var items_appear = create_tween().set_parallel(true)
	items_appear.tween_property(developer_image, "modulate:a", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	items_appear.tween_property(photo_image, "modulate:a", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await items_appear.finished
	
	# 玩家凝視兩個物件
	await get_tree().create_timer(1.5).timeout
	
	# 3: 顯影液靠近照片 (向中間移動) + 暗房紅光開始浮現
	var dev_start_x = developer_image.position.x
	var photo_start_x = photo_image.position.x
	var center_x = (dev_start_x + photo_start_x) / 2.0
	
	var merge = create_tween().set_parallel(true)
	merge.tween_property(developer_image, "position:x", center_x - developer_image.size.x / 2.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	merge.tween_property(photo_image, "position:x", center_x - photo_image.size.x / 2.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	merge.tween_property(developing_effect, "color:a", 0.7, 1.5)
	await merge.finished
	
	# 4: 兩物件淡出 (融合到沖洗過程)
	var items_fade = create_tween().set_parallel(true)
	items_fade.tween_property(developer_image, "modulate:a", 0.0, 1.0)
	items_fade.tween_property(photo_image, "modulate:a", 0.0, 1.0)
	await items_fade.finished
	
	await get_tree().create_timer(1.0).timeout
	
	# 5: "TRUTH REVEALED" 浮現
	var truth = create_tween()
	truth.tween_property(truth_label, "modulate:a", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await truth.finished
	
	await get_tree().create_timer(1.0).timeout
	
	# # 6: 紅光退去 + 真相照片從黑暗中浮現 + "TRUTH REVEALED" 字淡出
	var reveal = create_tween().set_parallel(true)
	reveal.tween_property(developing_effect, "color:a", 0.0, 3.0)
	reveal.tween_property(photo_reveal, "modulate:a", 1.0, 4.0)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reveal.tween_property(truth_label, "modulate:a", 0.0, 2.0)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await reveal.finished
	
	# 7: 副標出現 — "You never left this bar." / 日期
	var subtitle = create_tween()
	subtitle.tween_property(subtitle_label, "modulate:a", 1.0, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await subtitle.finished
	
	# 8: 玩家消化 10 秒
	await get_tree().create_timer(5.0).timeout
	
	# 9: 全部 fade to black
	var fade_out = create_tween().set_parallel(true)
	fade_out.tween_property(final_overlay, "color:a", 1.0, 3.0)
	fade_out.tween_property(photo_reveal, "modulate:a", 0.0, 2.5)
	fade_out.tween_property(truth_label, "modulate:a", 0.0, 2.5)
	fade_out.tween_property(subtitle_label, "modulate:a", 0.0, 2.5)
	await fade_out.finished
	
	await get_tree().create_timer(1.0).timeout
	
	# 10: Restart / End 按鈕
	restart_button.visible = true
	end_button.visible = true
	var buttons_in = create_tween().set_parallel(true)
	buttons_in.tween_property(restart_button, "modulate:a", 1.0, 1.5)
	buttons_in.tween_property(end_button, "modulate:a", 1.0, 1.5)
	await buttons_in.finished


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://main_game.tscn")


func _on_end_pressed() -> void:
	get_tree().quit()
