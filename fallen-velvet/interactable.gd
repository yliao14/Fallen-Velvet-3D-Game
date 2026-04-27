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
}

@export var interactable_type: InteractableType = InteractableType.VODKA
@export var prompt_text: String = "Press [E] to pick up"
@export var repeatable: bool = false
@export var letter_char: String = ""        # 字母本身，例如 "U"
@export var letter_index: int = 0           # 在 UPSTAIRS 中的位置 (0~7)

var is_used: bool = false

signal interacted(type: InteractableType, source: Interactable)


func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	print("🎯 interact() 觸發，type = ", interactable_type)
	if is_used and not repeatable:
		print("⚠️ 已使用過，跳過")
		return
	
	
	match interactable_type:
		InteractableType.RECIPE:
			GameManager.collect_recipe()
			# Recipe 不消失，玩家可以重複互動（但只觸發一次首次顯示）
		InteractableType.VODKA:
			print("🍾 呼叫 collect_item(vodka)")
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
			GameManager.find_cocktail_glass()
		InteractableType.LETTER:                              # ⭐ NEW
			var letter_id = letter_char + "_" + str(letter_index)
			GameManager.collect_letter(letter_id)
			_disappear()
	
	# 發出 signal 給其他系統
	interacted.emit(interactable_type, self)


# 一次性物件（材料）拾取後消失
func _disappear() -> void:
	is_used = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y + 0.5, 0.5)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	queue_free()
