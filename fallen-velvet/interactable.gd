class_name Interactable
extends StaticBody3D  

enum InteractableType {
	RECIPE,
	VODKA,
	TOMATO,
	LEMON,
	PEPPER,
	CELERY,
	COCKTAIL_GLASS,
	LETTER,
	PUZZLE_PIECE,
	DEVELOPER,
	FLASHLIGHT, 
	LOCKER,
}

@export var interactable_type: InteractableType = InteractableType.VODKA
@export var prompt_text: String = "Press [E] to pick up"
@export var repeatable: bool = false
@export var letter_char: String = ""        # 字母本身，例如 "U"
@export var letter_index: int = 0   
@export var code_digit: String = ""        # 在 UPSTAIRS 中的位置 (0~7)

var is_used: bool = false

signal interacted(type: InteractableType, source: Interactable)


func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	if is_used and not repeatable:
		return
	
	
	match interactable_type:
		InteractableType.RECIPE:
			if not GameManager.has_recipe:
				GameManager.collect_recipe()
	
		# 不論第幾次，都打開 recipe UI
			var recipe_ui = get_tree().get_first_node_in_group("recipe_ui")
			if recipe_ui and recipe_ui.has_method("show_fullscreen"):
				recipe_ui.show_fullscreen()
		InteractableType.VODKA:
			GameManager.collect_item("vodka")
			_disappear()
		InteractableType.TOMATO:
			GameManager.collect_item("tomato")
			_disappear()
		InteractableType.LEMON:
			GameManager.collect_item("lemon")
			_disappear()
		InteractableType.PEPPER:
			GameManager.collect_item("pepper")
			_disappear()
		InteractableType.CELERY:
			GameManager.collect_item("celery")
			_disappear()
		InteractableType.COCKTAIL_GLASS:
			if not GameManager.has_cocktail_glass:
				GameManager.find_cocktail_glass()
			else:
				var mixer = get_tree().get_first_node_in_group("cocktail_mixer")
				if mixer and mixer.has_method("_on_glass_found"):
					mixer._on_glass_found()
		InteractableType.LETTER:
			if GameManager.current_stage < GameManager.QuestStage.FIND_LETTERS:
				var toast = get_tree().get_first_node_in_group("toast_ui")
				if toast and toast.has_method("show_toast"):
					toast.show_toast("Mix the cocktail first.")
					return
			
			var letter_id = letter_char + "_" + str(letter_index)
			GameManager.collect_letter(letter_id)
			_disappear()
		InteractableType.PUZZLE_PIECE:
			var puzzle_ui = get_tree().get_first_node_in_group("puzzle_image_ui")
			if puzzle_ui and puzzle_ui.has_method("open_puzzle"):
				puzzle_ui.open_puzzle()
		InteractableType.DEVELOPER:
			GameManager.obtain_developer()
			_disappear()
		InteractableType.FLASHLIGHT:
			GameManager.obtain_flashlight()
			_disappear()
		InteractableType.LOCKER:
			var lock_ui = get_tree().get_first_node_in_group("code_lock_ui")
			if lock_ui and lock_ui.has_method("open_lock"):
				lock_ui.open_lock()
	
	# 發出 signal 給其他系統
	interacted.emit(interactable_type, self)


# 一次性物件（材料）拾取後消失
func _disappear() -> void:
	is_used = true
	AudioManager.play_pickup() 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y + 0.5, 0.5)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	queue_free()

# 數字記下後的視覺反饋
func _on_code_recorded() -> void:
	is_used = true
	# 數字短暫閃爍後固定發光（已記錄狀態）
	if has_node("DigitVisual"):
		$DigitVisual.set_recorded()
