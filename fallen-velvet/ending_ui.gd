extends CanvasLayer

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var developing_effect: ColorRect = $DevelopingEffect
@onready var photo_reveal: TextureRect = $PhotoReveal
@onready var truth_label: Label = $TruthLabel
@onready var end_label: Label = $EndLabel

@onready var developer_image: TextureRect = $DeveloperImage
@onready var photo_image: TextureRect = $PhotoImage
@onready var subtitle_label: Label = $SubtitleLabel
@onready var final_overlay: ColorRect = $FinalOverlay
@onready var develop_button: Button = $DevelopButton
@onready var restart_button: Button = $RestartButton
@onready var end_button: Button = $EndButton

var player: Node = null


func _ready() -> void:
	add_to_group("ending_ui")
	visible = false
	
	dark_overlay.color = Color(0, 0, 0, 0)
	developing_effect.color = Color(0.6, 0.05, 0.05, 0)
	photo_reveal.modulate.a = 0.0
	truth_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	end_label.modulate.a = 0.0
	developer_image.modulate.a = 0.0
	photo_image.modulate.a = 0.0
	final_overlay.color = Color(0, 0, 0, 0)
	
	develop_button.modulate.a = 0.0
	develop_button.visible = false
	restart_button.modulate.a = 0.0
	end_button.modulate.a = 0.0
	restart_button.visible = false
	end_button.visible = false
	
	develop_button.pressed.connect(_on_develop_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	end_button.pressed.connect(_on_end_pressed)
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


# Stage 1: locker unlock 觸發,顯示物件後等 develop button

func start_developing() -> void:
	visible = true
	
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(true)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	await _play_intro()


func _play_intro() -> void:
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
	
	await get_tree().create_timer(1.0).timeout
	
	# 3: Develop button 浮現 + 脈動
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	develop_button.visible = true
	develop_button.pivot_offset = develop_button.size / 2.0
	develop_button.scale = Vector2(0.9, 0.9)
	
	var btn_in = create_tween().set_parallel(true)
	btn_in.tween_property(develop_button, "modulate:a", 1.0, 0.8)
	btn_in.tween_property(develop_button, "scale", Vector2.ONE, 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await btn_in.finished
	
	_pulse_develop_button()


func _pulse_develop_button() -> void:
	var pulse = create_tween()
	pulse.set_loops()
	pulse.tween_property(develop_button, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(develop_button, "modulate", Color.WHITE, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Stage 2: develop button 按下後觸發

func _on_develop_pressed() -> void:
	GameManager.developing_started.emit()
	
	var btn_fade = create_tween()
	btn_fade.tween_property(develop_button, "modulate:a", 0.0, 0.5)
	await btn_fade.finished
	develop_button.visible = false
	
	await _play_revelation()


func _play_revelation() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	# 4: 顯影液靠近照片 + 紅光
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
	
	# 5: 兩物件淡出
	var items_fade = create_tween().set_parallel(true)
	items_fade.tween_property(developer_image, "modulate:a", 0.0, 1.0)
	items_fade.tween_property(photo_image, "modulate:a", 0.0, 1.0)
	await items_fade.finished
	
	await get_tree().create_timer(1.0).timeout
	
	# 6: TRUTH REVEALED
	var truth = create_tween()
	truth.tween_property(truth_label, "modulate:a", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await truth.finished
	
	await get_tree().create_timer(1.5).timeout
	
	# 7: 紅光退 + 真相浮現 + truth label 淡出
	var reveal = create_tween().set_parallel(true)
	reveal.tween_property(developing_effect, "color:a", 0.0, 3.0)
	reveal.tween_property(photo_reveal, "modulate:a", 1.0, 4.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reveal.tween_property(truth_label, "modulate:a", 0.0, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await reveal.finished
	
	await get_tree().create_timer(2.0).timeout
	
	# 8: 副標
	var subtitle = create_tween()
	subtitle.tween_property(subtitle_label, "modulate:a", 1.0, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await subtitle.finished
	
	# 9: 凝視 10 秒
	await get_tree().create_timer(5.0).timeout
	
	# 10: fade to black
	var fade_out = create_tween().set_parallel(true)
	fade_out.tween_property(final_overlay, "color:a", 1.0, 3.0)
	fade_out.tween_property(photo_reveal, "modulate:a", 0.0, 2.5)
	fade_out.tween_property(subtitle_label, "modulate:a", 0.0, 2.5)
	await fade_out.finished
	
	await get_tree().create_timer(1.0).timeout
	
	# 11: Restart / End
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	restart_button.visible = true
	end_button.visible = true
	var buttons_in = create_tween().set_parallel(true)
	buttons_in.tween_property(restart_button, "modulate:a", 1.0, 1.5)
	buttons_in.tween_property(end_button, "modulate:a", 1.0, 1.5)
	await buttons_in.finished


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_end_pressed() -> void:
	get_tree().quit()
