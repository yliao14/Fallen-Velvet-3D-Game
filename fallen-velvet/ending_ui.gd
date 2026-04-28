extends CanvasLayer

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var developing_effect: ColorRect = $DevelopingEffect
@onready var photo_reveal: TextureRect = $PhotoReveal
@onready var truth_label: Label = $TruthLabel
@onready var end_label: Label = $EndLabel

var player: Node = null
var can_exit: bool = false


func _ready() -> void:
	add_to_group("ending_ui")
	visible = false
	
	dark_overlay.color = Color(0, 0, 0, 0)
	developing_effect.color = Color(0.6, 0.05, 0.05, 0)
	photo_reveal.modulate.a = 0.0
	truth_label.modulate.a = 0.0
	end_label.modulate.a = 0.0
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


func start_developing() -> void:
	visible = true
	can_exit = false
	
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
	
	# 2: 暗房紅光
	var red = create_tween()
	red.tween_property(developing_effect, "color:a", 0.7, 2.0)
	await red.finished
	
	await get_tree().create_timer(1.0).timeout
	
	# 3: "Reveal the truth" 文字浮現
	var truth = create_tween()
	truth.tween_property(truth_label, "modulate:a", 1.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await truth.finished
	
	await get_tree().create_timer(2.0).timeout
	
	# 4: 紅光退去，照片從黑暗中浮現
	var reveal = create_tween().set_parallel(true)
	reveal.tween_property(developing_effect, "color:a", 0.0, 3.0)
	reveal.tween_property(photo_reveal, "modulate:a", 1.0, 4.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await reveal.finished
	
	# 玩家凝視
	await get_tree().create_timer(3.0).timeout
	
	# 5: THE END
	var ending = create_tween()
	ending.tween_property(end_label, "modulate:a", 1.0, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await ending.finished
	
	await get_tree().create_timer(3.0).timeout
	
	# 6: 可以離開了
	can_exit = true
	_show_exit_prompt()


func _show_exit_prompt() -> void:
	var exit_label = Label.new()
	exit_label.text = "Press any key"
	exit_label.modulate.a = 0.0
	exit_label.add_theme_font_size_override("font_size", 24)
	exit_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	exit_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	exit_label.position.y -= 40
	exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(exit_label)
	
	var appear = create_tween()
	appear.tween_property(exit_label, "modulate:a", 1.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not can_exit:
		return
	
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
