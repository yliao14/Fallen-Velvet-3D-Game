extends Node

# SIGNALS

# Recipe & ingredients
signal recipe_found
signal item_collected(item_id: String)

# Cocktail
signal cocktail_glass_found
signal cocktail_completed
signal photo_obtained

# Letters & puzzle
signal letter_collected(letter: String)
signal puzzle_completed
signal puzzle_image_completed
signal panel_opened

# Developer & flashlight
signal developer_obtained
signal lights_dimmed
signal flashlight_obtained
signal flashlight_state_changed(is_on: bool)

# Locker
signal code_lock_unlocked
signal locker_unlocked
signal developing_started

# Quest
signal quest_stage_changed(new_stage: QuestStage)


# QUEST STAGES

enum QuestStage {
	FIND_RECIPE,
	COLLECT_INGREDIENTS,
	FIND_GLASS,
	MIX_COCKTAIL,
	FIND_LETTERS,
	SOLVE_PUZZLE,
	FIND_DEVELOPER,
	FIND_FLASHLIGHT,
	UNLOCK_LOCKER,
	DEVELOP_PHOTO,
}

const QUEST_TEXTS: Dictionary = {
	QuestStage.FIND_RECIPE: "Find the recipe",
	QuestStage.COLLECT_INGREDIENTS: "Find the ingredients",
	QuestStage.FIND_GLASS: "Find the cocktail glass",
	QuestStage.MIX_COCKTAIL: "Mix the cocktail",
	QuestStage.FIND_LETTERS: "Find the letter cards",
	QuestStage.SOLVE_PUZZLE: "Piece together the image",
	QuestStage.FIND_DEVELOPER: "Find the developer fluid",
	QuestStage.FIND_FLASHLIGHT: "Find a flashlight",
	QuestStage.UNLOCK_LOCKER: "Unlock the locker",
	QuestStage.DEVELOP_PHOTO: "Develop the photo",
}

var current_stage: QuestStage = QuestStage.FIND_RECIPE


# CONSTANTS

const ALL_INGREDIENTS: Array[String] = ["vodka", "tomato", "lemon", "pepper", "celery"]

const INGREDIENT_NAMES: Dictionary = {
	"vodka": "Vodka",
	"tomato": "Tomato Juice",
	"lemon": "Lemon",
	"pepper": "Black Pepper",
	"celery": "Celery",
}

const TARGET_WORD: String = "UPSTAIRS"
const TARGET_CODE: String = "427"


# PLAYER STATE

var has_recipe: bool = false
var has_cocktail_glass: bool = false
var is_cocktail_completed: bool = false
var has_photo: bool = false
var is_puzzle_image_completed: bool = false
var has_developer: bool = false
var has_flashlight: bool = false
var is_room_dimmed: bool = false
var is_flashlight_on: bool = false
var is_locker_unlocked: bool = false

var inventory: Dictionary = {
	"vodka": false,
	"tomato": false,
	"lemon": false,
	"pepper": false,
	"celery": false,
}

var cocktail_contents: Array[String] = []
var collected_letters: Dictionary = {}


# LIFECYCLE

func _ready() -> void:
	# Initialize letter tracking based on TARGET_WORD
	for i in range(TARGET_WORD.length()):
		var key = TARGET_WORD[i] + "_" + str(i)
		collected_letters[key] = false


# RECIPE

func collect_recipe() -> void:
	if has_recipe:
		return
	has_recipe = true
	recipe_found.emit()
	_advance_quest(QuestStage.COLLECT_INGREDIENTS)
	_show_toast("[R] toggle the recipe")


# INGREDIENTS / INVENTORY

func collect_item(item_id: String) -> void:
	if not inventory.has(item_id):
		push_warning("Unknown item_id: " + item_id)
		return
	if inventory[item_id]:
		return
	
	inventory[item_id] = true
	item_collected.emit(item_id)
	
	if _all_ingredients_collected():
		_advance_quest(QuestStage.FIND_GLASS)


func has_item(item_id: String) -> bool:
	return inventory.get(item_id, false)


func _all_ingredients_collected() -> bool:
	for item_id in ALL_INGREDIENTS:
		if not inventory.get(item_id, false):
			return false
	return true


# COCKTAIL

func find_cocktail_glass() -> void:
	if has_cocktail_glass:
		return
	has_cocktail_glass = true
	cocktail_glass_found.emit()
	_advance_quest(QuestStage.MIX_COCKTAIL)


func add_to_cocktail(item_id: String) -> bool:
	if not inventory.get(item_id, false):
		return false
	if item_id in cocktail_contents:
		return false
	
	inventory[item_id] = false
	cocktail_contents.append(item_id)
	return true


func is_cocktail_ready_to_mix() -> bool:
	return cocktail_contents.size() == ALL_INGREDIENTS.size()


func complete_cocktail() -> void:
	if is_cocktail_completed:
		return
	is_cocktail_completed = true
	cocktail_completed.emit()
	# Note: photo is granted later by cocktail_mixer when its animation finishes
	_advance_quest(QuestStage.FIND_LETTERS)


func grant_photo() -> void:
	if has_photo:
		return
	has_photo = true
	photo_obtained.emit()


# LETTERS & PUZZLE

func collect_letter(letter_id: String) -> void:
	if not collected_letters.has(letter_id):
		return
	if collected_letters[letter_id]:
		return
	
	collected_letters[letter_id] = true
	letter_collected.emit(letter_id)
	
	if _all_letters_collected():
		puzzle_completed.emit()
		_advance_quest(QuestStage.SOLVE_PUZZLE)


func get_letter_progress() -> int:
	var count = 0
	for key in collected_letters.keys():
		if collected_letters[key]:
			count += 1
	return count


func _all_letters_collected() -> bool:
	for key in collected_letters.keys():
		if not collected_letters[key]:
			return false
	return true


func complete_puzzle_image() -> void:
	if is_puzzle_image_completed:
		return
	is_puzzle_image_completed = true
	puzzle_image_completed.emit()
	
	# Auto-open the panel 1 second after puzzle completes
	await get_tree().create_timer(1.0).timeout
	panel_opened.emit()
	_advance_quest(QuestStage.FIND_DEVELOPER)


# DEVELOPER & FLASHLIGHT

func obtain_developer() -> void:
	if has_developer:
		return
	has_developer = true
	developer_obtained.emit()
	_advance_quest(QuestStage.FIND_FLASHLIGHT)
	_dim_lights()


func obtain_flashlight() -> void:
	if has_flashlight:
		return
	has_flashlight = true
	flashlight_obtained.emit()
	_advance_quest(QuestStage.UNLOCK_LOCKER)
	_show_toast("[F] turn on the flashlight")


func toggle_flashlight() -> void:
	if not is_room_dimmed:
		return
	is_flashlight_on = not is_flashlight_on
	flashlight_state_changed.emit(is_flashlight_on)
	print("🔦 Flashlight: ", "ON" if is_flashlight_on else "OFF")


func _dim_lights() -> void:
	if is_room_dimmed:
		return
	is_room_dimmed = true
	lights_dimmed.emit()


# LOCKER

func attempt_code_unlock(input_code: String) -> bool:
	if input_code == TARGET_CODE:
		code_lock_unlocked.emit()
		unlock_locker()
		print("Code correct!")
		return true
	print("Wrong code: ", input_code)
	return false


func unlock_locker() -> void:
	if is_locker_unlocked:
		return
	is_locker_unlocked = true
	locker_unlocked.emit()
	_advance_quest(QuestStage.DEVELOP_PHOTO)
	print("Locker unlocked")
	
	# 等 code lock UI 淡出後啟動 ending intro
	await get_tree().create_timer(1.5).timeout
	var ending = get_tree().get_first_node_in_group("ending_ui")
	if ending and ending.has_method("start_developing"):
		ending.start_developing()


# QUEST HELPERS

func get_current_quest_text() -> String:
	return QUEST_TEXTS.get(current_stage, "")


func _advance_quest(new_stage: QuestStage) -> void:
	if new_stage == current_stage:
		return
	current_stage = new_stage
	quest_stage_changed.emit(new_stage)
	print("   Quest advanced: ", get_current_quest_text())


# UTILITY

func _show_toast(message: String) -> void:
	var toast = get_tree().get_first_node_in_group("toast_ui")
	if toast and toast.has_method("show_toast"):
		toast.show_toast(message)
