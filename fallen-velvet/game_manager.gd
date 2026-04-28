extends Node

# === 訊號 ===
signal recipe_found
signal item_collected(item_id: String)
signal cocktail_glass_found
signal cocktail_completed
signal quest_stage_changed(new_stage: QuestStage)
signal photo_obtained
signal letter_collected(letter: String)
signal puzzle_completed
signal puzzle_image_completed
signal panel_opened         
signal developer_obtained    
signal lights_dimmed
signal flashlight_state_changed(is_on: bool)
signal flashlight_obtained
signal code_found(digit: int)        
signal all_codes_found                  
signal code_lock_unlocked    

# === 任務階段 ===
enum QuestStage {
	FIND_RECIPE,
	COLLECT_INGREDIENTS,
	FIND_GLASS,
	MIX_COCKTAIL,
	FIND_LETTERS,
	SOLVE_PUZZLE, 
	FIND_DEVELOPER,
	FIND_FLASHLIGHT,
	FIND_CODES,
}

var current_stage: QuestStage = QuestStage.FIND_RECIPE

# === 玩家進度狀態 ===
var has_recipe: bool = false
var has_cocktail_glass: bool = false
var is_cocktail_completed: bool = false
var has_photo: bool = false
var has_developer: bool = false
var is_room_dimmed: bool = false
var is_flashlight_on: bool = false
var has_flashlight: bool = false

# === Inventory ===
var inventory: Dictionary = {
	"vodka": false,
	"tomato": false,
	"lemon": false,
	"pepper": false,
	"celery": false,
}

var cocktail_contents: Array[String] = []

# === 字母拼字系統 ===
const TARGET_WORD: String = "UPSTAIRS"
var collected_letters: Dictionary = {}

var is_puzzle_image_completed: bool = false

const ALL_INGREDIENTS: Array[String] = ["vodka", "tomato", "lemon", "pepper", "celery"]

const INGREDIENT_NAMES: Dictionary = {
	"vodka": "Vodka",
	"tomato": "Tomato Juice",
	"lemon": "Lemon",
	"pepper": "Black Pepper",
	"celery": "Celery",
}

const QUEST_TEXTS: Dictionary = {
	QuestStage.FIND_RECIPE: "Find the recipe",
	QuestStage.COLLECT_INGREDIENTS: "Find the ingredients",
	QuestStage.FIND_GLASS: "Find the cocktail glass",
	QuestStage.MIX_COCKTAIL: "Mix the cocktail",
	QuestStage.FIND_LETTERS: "Find the letters",
	QuestStage.SOLVE_PUZZLE: "Piece together the image",
	QuestStage.FIND_DEVELOPER: "Find the developer fluid",
	QuestStage.FIND_FLASHLIGHT: "Find a flashlight",
	QuestStage.FIND_CODES: "Find the hidden codes",
}

const TARGET_CODE: String = "427"
var found_codes: Dictionary = {
	"4": false,
	"2": false,
	"7": false,
}


func _ready() -> void:
	# 初始化 letter 追蹤
	for i in range(TARGET_WORD.length()):
		var key = TARGET_WORD[i] + "_" + str(i)
		collected_letters[key] = false


func collect_recipe() -> void:
	if has_recipe:
		print("cannot pick up")
		return
	has_recipe = true
	recipe_found.emit()
	_advance_quest(QuestStage.COLLECT_INGREDIENTS)
	
	var toast = get_tree().get_first_node_in_group("toast_ui")
	if toast:
		toast.show_toast("[R] toggle the recipe")


func collect_item(item_id: String) -> void:
	if not inventory.has(item_id):
		push_warning("未知的 item_id: " + item_id)
		return
	if inventory[item_id]:
		return
	
	inventory[item_id] = true
	item_collected.emit(item_id)

	
	if _all_ingredients_collected():
		_advance_quest(QuestStage.FIND_GLASS)


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
	
	# has_photo + photo_obtained 改成由 cocktail_mixer 在動畫結束時觸發
	
	_advance_quest(QuestStage.FIND_LETTERS)
	

func grant_photo() -> void:
	if has_photo:
		return
	has_photo = true
	photo_obtained.emit()

	


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
	
		


func has_item(item_id: String) -> bool:
	return inventory.get(item_id, false)


func _advance_quest(new_stage: QuestStage) -> void:

	if new_stage == current_stage:
		print("   → same stage, skip")
		return
	current_stage = new_stage
	quest_stage_changed.emit(new_stage)
	print("   ✅ signal emitted, new text: ", get_current_quest_text()) 


func _all_ingredients_collected() -> bool:
	for item_id in ALL_INGREDIENTS:
		if not inventory.get(item_id, false):
			return false
	return true


func _all_letters_collected() -> bool:
	for key in collected_letters.keys():
		if not collected_letters[key]:
			return false
	return true


func get_current_quest_text() -> String:
	return QUEST_TEXTS.get(current_stage, "")


func get_letter_progress() -> int:
	var count = 0
	for key in collected_letters.keys():
		if collected_letters[key]:
			count += 1
	return count
	
func complete_puzzle_image() -> void:
	if is_puzzle_image_completed:
		return
	is_puzzle_image_completed = true
	puzzle_image_completed.emit()
	
	# 拼圖完成後 1 秒自動觸發板子開啟
	await get_tree().create_timer(1.0).timeout
	panel_opened.emit()
	
	_advance_quest(QuestStage.FIND_DEVELOPER)

	
	
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
	_advance_quest(QuestStage.FIND_CODES)
	_show_toast("[F] turn on the flashlight")

func _dim_lights() -> void:
	if is_room_dimmed:
		return
	is_room_dimmed = true
	lights_dimmed.emit()



func toggle_flashlight() -> void:

	if not is_room_dimmed:
		return
	is_flashlight_on = not is_flashlight_on
	flashlight_state_changed.emit(is_flashlight_on)
	print("🔦 手電筒: ", "ON" if is_flashlight_on else "OFF")
	
# Helper
func _show_toast(message: String) -> void:
	var toast = get_tree().get_first_node_in_group("toast_ui")
	if toast and toast.has_method("show_toast"):
		toast.show_toast(message)
		
func find_code(digit: String) -> void:
	if not found_codes.has(digit):
		push_warning("Unknown code digit: " + digit)
		return
	if found_codes[digit]:
		return
	
	found_codes[digit] = true
	code_found.emit(int(digit))
	print("🔢 找到密碼數字: ", digit)
	
	if _all_codes_found():
		all_codes_found.emit()
		print("🎉 三個密碼都找到了！")


func _all_codes_found() -> bool:
	for digit in found_codes.keys():
		if not found_codes[digit]:
			return false
	return true


func attempt_code_unlock(input_code: String) -> bool:
	if input_code == TARGET_CODE:
		code_lock_unlocked.emit()
		print("🔓 密碼正確！")
		return true
	else:
		print("❌ 密碼錯誤: ", input_code)
		return false
