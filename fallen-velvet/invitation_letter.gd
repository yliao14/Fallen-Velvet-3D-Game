extends Control

@onready var skip_button: Button = $SkipButton
@onready var letter_image: TextureRect = $LetterImage
@onready var letter_text: RichTextLabel = $LetterText
@onready var footer_text: RichTextLabel = $FooterText

# === 信件主文 ===
const LETTER_CONTENT: String = """[i]Rose Moretti,[/i]

If this found you, then maybe you still know how to follow a place that no longer exists.

We are waiting for you again.

Same street. Same stairs. Same red door.

Come after midnight.

There is something from that night you never developed. Something you left behind. Or something that was left for you.

You once knew how to look closer than anyone else.

So come alone.
Bring your eyes.
Bring your nerve.
And if you still have the letter, bring that too.

[i]Don't be late this time.[/i]"""

# === Footer 簽名 ===
const FOOTER_CONTENT: String = "— Fallen Velvet"

# === 可調參數 ===
@export var type_speed: float = 0.04           # 主文打字速度
@export var footer_type_speed: float = 0.12    # Footer 打字速度（慢一點，更有戲劇感）
@export var pause_before_footer: float = 1.2   # 主文打完到 footer 開始的停頓
@export var fade_duration: float = 0.6

# === 標點停頓 ===
@export var pause_after_period: float = 0.4
@export var pause_after_comma: float = 0.15
@export var pause_after_newline: float = 0.3

# === Button 文字 ===
const SKIP_TEXT: String = "Skip ▶"
const CONTINUE_TEXT: String = "Continue ▶"

var is_transitioning: bool = false
var is_typing: bool = false
var typing_finished: bool = false


func _ready() -> void:
	# 連結 button
	skip_button.pressed.connect(_on_button_pressed)
	skip_button.mouse_entered.connect(_on_button_hover)
	skip_button.mouse_exited.connect(_on_button_unhover)
	skip_button.pivot_offset = skip_button.size / 2.0
	skip_button.text = SKIP_TEXT
	
	# 設定文字（先清空兩段）
	letter_text.bbcode_enabled = true
	footer_text.bbcode_enabled = true
	letter_text.text = ""
	footer_text.text = ""
	
	# 進場淡入後開始打字
	_fade_in()


func _fade_in() -> void:
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_callback(_start_typing)


func _start_typing() -> void:
	is_typing = true
	
	# 第一段：主文
	await _type_text(letter_text, LETTER_CONTENT, type_speed)
	if not is_typing:
		return  # 玩家已經按 skip 跳過了
	
	# 主文打完後停頓一下，營造期待感
	await get_tree().create_timer(pause_before_footer).timeout
	if not is_typing:
		return
	
	# 第二段：footer 簽名（用慢速，每個字像在強調）
	await _type_text(footer_text, FOOTER_CONTENT, footer_type_speed)
	
	is_typing = false
	_on_typing_complete()


func _type_text(target_label: RichTextLabel, full_text: String, speed: float) -> void:
	var i: int = 0
	while i < full_text.length():
		# 中斷檢查
		if not is_typing:
			return
		
		var current_char: String = full_text[i]
		
		# BBCode tag 整段一起加
		if current_char == "[":
			var tag_end: int = full_text.find("]", i)
			if tag_end != -1:
				target_label.text += full_text.substr(i, tag_end - i + 1)
				i = tag_end + 1
				continue
		
		target_label.text += current_char
		i += 1
		
		# 標點停頓
		var wait_time: float = speed
		match current_char:
			".", "!", "?":
				wait_time += pause_after_period
			",", ";", ":":
				wait_time += pause_after_comma
			"\n":
				wait_time += pause_after_newline
		
		await get_tree().create_timer(wait_time).timeout


func _on_typing_complete() -> void:
	typing_finished = true
	_animate_button_change()


func _animate_button_change() -> void:
	# Skip → Continue 平滑切換
	var tween = create_tween()
	tween.tween_property(skip_button, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): skip_button.text = CONTINUE_TEXT)
	tween.tween_property(skip_button, "modulate:a", 1.0, 0.3)
	
	# 持續呼吸脈動，提示可以點
	_start_button_pulse()


func _start_button_pulse() -> void:
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(skip_button, "modulate", Color(1.2, 1.2, 1.2), 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(skip_button, "modulate", Color(1.0, 1.0, 1.0), 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_button_pressed() -> void:
	if is_transitioning:
		return
	
	# 還在打字 → 一鍵補完所有文字
	if is_typing:
		is_typing = false
		letter_text.text = LETTER_CONTENT
		footer_text.text = FOOTER_CONTENT
		_on_typing_complete()
		return
	
	# 已打完 → 進入遊戲
	if typing_finished:
		_go_to_main_game()


func _go_to_main_game() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	skip_button.disabled = true
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://main_game.tscn")
	)


func _on_button_hover() -> void:
	var tween = create_tween()
	tween.tween_property(skip_button, "scale", Vector2(1.1, 1.1), 0.15)


func _on_button_unhover() -> void:
	var tween = create_tween()
	tween.tween_property(skip_button, "scale", Vector2(1.0, 1.0), 0.15)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_button_pressed()
