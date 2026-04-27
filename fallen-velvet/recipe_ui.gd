extends CanvasLayer

@onready var fullscreen_view: Control = $FullscreenView
@onready var close_button: Button = $FullscreenView/CloseButton
@onready var recipe_icon: Button = $IconView/RecipeIcon

var player: Node = null
var has_shown_first_time: bool = false


func _ready() -> void:
	add_to_group("recipe_ui")
	
	fullscreen_view.visible = false
	recipe_icon.visible = false
	
	close_button.pressed.connect(_on_close_pressed)
	recipe_icon.pressed.connect(show_fullscreen)
	
	GameManager.recipe_found.connect(_on_recipe_found)
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


func _on_recipe_found() -> void:
	if not has_shown_first_time:
		has_shown_first_time = true
		show_fullscreen()


func show_fullscreen() -> void:
	fullscreen_view.visible = true
	fullscreen_view.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(fullscreen_view, "modulate:a", 1.0, 0.4)
	
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(true)


func _on_close_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(fullscreen_view, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_after_close)


func _after_close() -> void:
	fullscreen_view.visible = false
	
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(false)
	
	# 第一次關閉後，icon 浮現
	if not recipe_icon.visible:
		_show_recipe_icon()


func _show_recipe_icon() -> void:
	recipe_icon.visible = true
	recipe_icon.scale = Vector2.ZERO
	recipe_icon.pivot_offset = recipe_icon.size / 2.0
	
	var tween = create_tween()
	tween.tween_property(recipe_icon, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	# 全螢幕食譜開著時，Esc 關閉
	if fullscreen_view.visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
		return
	
	if not GameManager.has_recipe:
		return
	
	# R 鍵切換食譜
	if event.is_action_pressed("toggle_recipe"):
		if fullscreen_view.visible:
			_on_close_pressed()
		else:
			show_fullscreen()
