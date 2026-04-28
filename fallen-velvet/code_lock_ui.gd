extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var lock_panel: Control = $LockPanel
@onready var hint_label: Label = $HintLabel

@onready var dials: Array[Label] = [
	$LockPanel/Dial_0,
	$LockPanel/Dial_1,
	$LockPanel/Dial_2,
]

var current_input: String = ""
var player: Node = null
var is_processing: bool = false   # 防止驗證中再次輸入


func _ready() -> void:
	add_to_group("code_lock_ui")
	visible = false
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	_update_display()


func _on_all_codes_found() -> void:
	await get_tree().create_timer(1.5).timeout
	open_lock()


func open_lock() -> void:
	visible = true
	current_input = ""
	is_processing = false
	_update_display()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(true)
	
	# 進場動畫
	background.modulate.a = 0.0
	lock_panel.modulate.a = 0.0
	lock_panel.scale = Vector2(0.85, 0.85)
	lock_panel.pivot_offset = lock_panel.size / 2.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(background, "modulate:a", 1.0, 0.4)
	tween.tween_property(lock_panel, "modulate:a", 1.0, 0.5)
	tween.tween_property(lock_panel, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_display() -> void:
	# 把每格 dial 顯示對應的數字（沒輸入的顯示 "_"）
	for i in range(dials.size()):
		if i < current_input.length():
			dials[i].text = current_input[i]
		else:
			dials[i].text = "_"


func _add_digit(digit: String) -> void:
	if is_processing:
		return
	if current_input.length() >= 3:
		return
	
	current_input += digit
	_update_display()
	
	# 輸入該格的小動畫
	var idx = current_input.length() - 1
	_play_dial_pop(idx)
	
	# 自動驗證：3 個都輸入完就判定
	if current_input.length() == 3:
		_validate()


func _clear_input() -> void:
	if is_processing:
		return
	current_input = ""
	_update_display()


func _play_dial_pop(index: int) -> void:
	var dial = dials[index]
	dial.pivot_offset = dial.size / 2.0
	dial.scale = Vector2(1.4, 1.4)
	
	var tween = create_tween()
	tween.tween_property(dial, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _validate() -> void:
	is_processing = true
	
	if GameManager.attempt_code_unlock(current_input):
		_on_unlock_success()
	else:
		_on_unlock_fail()


func _on_unlock_success() -> void:
	for dial in dials:
		var tween = create_tween()
		tween.tween_property(dial, "modulate", Color(0.3, 1.0, 0.4), 0.3)
	
	hint_label.text = "Unlocked"
	hint_label.modulate = Color(0.3, 1.0, 0.4)
	
	await get_tree().create_timer(1.5).timeout
	
	var fade = create_tween().set_parallel(true)
	fade.tween_property(background, "modulate:a", 0.0, 1.0)
	fade.tween_property(lock_panel, "modulate:a", 0.0, 1.0)
	fade.tween_property(hint_label, "modulate:a", 0.0, 1.0)
	await fade.finished
	
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(false)
	
	var toast = get_tree().get_first_node_in_group("toast_ui")
	if toast:
		toast.show_toast("Locker unlocked — check your inventory")
	
	GameManager.unlock_locker() 


func _on_unlock_fail() -> void:
	# 紅色閃光 + 震動
	for dial in dials:
		var tween = create_tween()
		tween.tween_property(dial, "modulate", Color(1.0, 0.3, 0.3), 0.2)
		tween.tween_property(dial, "modulate", Color.WHITE, 0.4)
	
	# 整個保險箱震動
	var original_x = lock_panel.position.x
	var shake = create_tween()
	for i in range(4):
		shake.tween_property(lock_panel, "position:x", original_x + 8, 0.05)
		shake.tween_property(lock_panel, "position:x", original_x - 8, 0.05)
	shake.tween_property(lock_panel, "position:x", original_x, 0.05)
	
	hint_label.text = "Wrong code"
	hint_label.modulate = Color(1.0, 0.4, 0.4)
	
	# 等動畫完，重置
	await get_tree().create_timer(0.8).timeout
	current_input = ""
	_update_display()
	hint_label.text = "Type the code (Backspace to clear)"
	hint_label.modulate = Color.WHITE
	is_processing = false


# 鍵盤輸入
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		
		# 數字 0-9（鍵盤上排）
		if key >= KEY_0 and key <= KEY_9:
			var digit = str(key - KEY_0)
			_add_digit(digit)
			get_viewport().set_input_as_handled()
		# 數字鍵盤 0-9
		elif key >= KEY_KP_0 and key <= KEY_KP_9:
			var digit = str(key - KEY_KP_0)
			_add_digit(digit)
			get_viewport().set_input_as_handled()
		# Backspace 清空
		elif key == KEY_BACKSPACE:
			_clear_input()
			get_viewport().set_input_as_handled()
		# Esc 關閉
		elif key == KEY_ESCAPE:
			_close_lock()
			get_viewport().set_input_as_handled()


func _close_lock() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(background, "modulate:a", 0.0, 0.3)
	tween.tween_property(lock_panel, "modulate:a", 0.0, 0.3)
	await tween.finished
	visible = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(false)
