extends Node3D

func _ready() -> void:
	visible = false
	GameManager.developer_obtained.connect(_on_developer_obtained)


func _on_developer_obtained() -> void:
	visible = true
