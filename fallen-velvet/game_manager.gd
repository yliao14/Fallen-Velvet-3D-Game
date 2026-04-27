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

# === 任務階段 ===
enum QuestStage {
	FIND_RECIPE,
	COLLECT_INGREDIENTS,
	FIND_GLASS,
	MIX_COCKTAIL,
	FIND_LETTERS,
	SOLVE_PUZZLE, 
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
	QuestStage.FIND_RECIPE: "Find the Recipe",
	QuestStage.COLLECT_INGREDIENTS: "Find the ingredients",
	QuestStage.FIND_GLASS: "Find the Cocktail Glass",
	QuestStage.MIX_COCKTAIL: "Mix the cocktail",
	QuestStage.FIND_LETTERS: "Find the letters",
	QuestStage.SOLVE_PUZZLE: "Piece together the image",
}


func _ready() -> void:
	# 初始化 letter 追蹤
	for i in range(TARGET_WORD.length()):
		var key = TARGET_WORD[i] + "_" + str(i)
		collected_letters[key] = false


func collect_recipe() -> void:
	if has_recipe:
		return
	has_recipe = true
	recipe_found.emit()
	_advance_quest(QuestStage.COLLECT_INGREDIENTS)
	print("📜 拿到食譜")


func collect_item(item_id: String) -> void:
	if not inventory.has(item_id):
		push_warning("未知的 item_id: " + item_id)
		return
	if inventory[item_id]:
		return
	
	inventory[item_id] = true
	item_collected.emit(item_id)
	print("✨ 拿到材料: " + item_id)
	
	if _all_ingredients_collected():
		_advance_quest(QuestStage.FIND_GLASS)


func find_cocktail_glass() -> void:
	if has_cocktail_glass:
		return
	has_cocktail_glass = true
	cocktail_glass_found.emit()
	_advance_quest(QuestStage.MIX_COCKTAIL)
	print("🥃 找到酒杯")


func add_to_cocktail(item_id: String) -> bool:
	if not inventory.get(item_id, false):
		return false
	if item_id in cocktail_contents:
		return false
	
	inventory[item_id] = false
	cocktail_contents.append(item_id)
	print("🍸 加入酒杯: " + item_id)
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
	print("🎬 調酒完成！")


# ⭐ NEW: 底片動畫播完後由 cocktail_mixer 呼叫
func grant_photo() -> void:
	if has_photo:
		return
	has_photo = true
	photo_obtained.emit()
	print("📷 底片進 inventory")
	


func collect_letter(letter_id: String) -> void:
	if not collected_letters.has(letter_id):
		return
	if collected_letters[letter_id]:
		return
	
	collected_letters[letter_id] = true
	letter_collected.emit(letter_id)
	print("🔤 撿到字母: ", letter_id)
	
	if _all_letters_collected():
		puzzle_completed.emit()
		_advance_quest(QuestStage.SOLVE_PUZZLE)   # ⭐ NEW
		print("🎉 字母拼完！UPSTAIRS")
		


func has_item(item_id: String) -> bool:
	return inventory.get(item_id, false)


func _advance_quest(new_stage: QuestStage) -> void:
	if new_stage == current_stage:
		return
	current_stage = new_stage
	quest_stage_changed.emit(new_stage)


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
	
	# ⭐ NEW: 拼圖完成後 1 秒自動觸發板子開啟
	await get_tree().create_timer(1.0).timeout
	panel_opened.emit()

	
	
func obtain_developer() -> void:
	if has_developer:
		return
	has_developer = true
	developer_obtained.emit()
	print("💧 拿到顯影液")
	
	# 自動觸發燈光全暗 + 啟用手電筒
	_dim_lights()


func _dim_lights() -> void:
	if is_room_dimmed:
		return
	is_room_dimmed = true
	lights_dimmed.emit()
	print("🌑 燈光全暗")


func toggle_flashlight() -> void:
	# 只有房間暗了才能開手電筒
	if not is_room_dimmed:
		return
	is_flashlight_on = not is_flashlight_on
	flashlight_state_changed.emit(is_flashlight_on)
	print("🔦 手電筒: ", "ON" if is_flashlight_on else "OFF")
