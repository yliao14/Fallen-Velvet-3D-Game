extends Node3D

# 環境光的目標亮度（玩家撿到顯影液前）
@export var normal_brightness: float = 1.0

# 變暗後的亮度
@export var dimmed_brightness: float = 0.05

# 找到場景中的 WorldEnvironment 或 DirectionalLight
@export var directional_light: DirectionalLight3D
@export var world_environment: WorldEnvironment


func _ready() -> void:
	GameManager.lights_dimmed.connect(_on_lights_dimmed)


func _on_lights_dimmed() -> void:
	print("🌑 開始燈光淡出")
	
	# DirectionalLight 淡出
	if directional_light:
		var tween = create_tween()
		tween.tween_property(directional_light, "light_energy", dimmed_brightness, 2.0)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# 環境光也淡出（如果有 WorldEnvironment）
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		var tween = create_tween()
		tween.tween_property(env, "ambient_light_energy", 0.05, 2.0)
