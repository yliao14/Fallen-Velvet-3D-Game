extends CanvasLayer

@onready var pause_button: TextureButton = $PauseButton
@onready var pause_menu: Control = $PauseMenu
@onready var resume_button: Button = $PauseMenu/ResumeButton
@onready var main_menu_button: Button = $PauseMenu/MainMenuButton
@onready var quit_button: Button = $PauseMenu/QuitButton

var player: Node = null
var is_disabled: bool = false


func _ready() -> void:
	# 暫停時 UI 仍能運作
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	pause_menu.visible = false
	
	pause_button.pressed.connect(_toggle_pause)
	resume_button.pressed.connect(_toggle_pause)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	
	GameManager.developing_started.connect(_on_developing_started)
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _on_developing_started() -> void:
	is_disabled = true
	var tween = create_tween()
	tween.tween_property(pause_button, "modulate:a", 0.0, 0.8)
	await tween.finished
	pause_button.visible = false

func _toggle_pause() -> void:
	if is_disabled:
		return
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	
	if is_paused:
		_show_pause_menu()
	else:
		_hide_pause_menu()


func _show_pause_menu() -> void:
	pause_menu.visible = true
	pause_menu.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(pause_menu, "modulate:a", 1.0, 0.3)
	
	# 釋放滑鼠
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _hide_pause_menu() -> void:
	var tween = create_tween()
	tween.tween_property(pause_menu, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): pause_menu.visible = false)
	
	# 鎖回滑鼠
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if is_disabled:
		return
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
