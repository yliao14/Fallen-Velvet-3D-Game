extends Node3D

func _ready() -> void:
	visible = false
	GameManager.quest_stage_changed.connect(_on_quest_changed)
	_check_visibility(GameManager.current_stage)


func _on_quest_changed(new_stage: int) -> void:
	_check_visibility(new_stage)


func _check_visibility(stage: int) -> void:
	if stage >= GameManager.QuestStage.FIND_LETTERS:
		visible = true
