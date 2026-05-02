extends Node

# 預載音檔
const BGM = preload("res://audio/bgm.mp3")
const SFX_PICKUP = preload("res://audio/pickup.mp3")
const SFX_CODE_CORRECT = preload("res://audio/code_correct.mp3")

# 節點 
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer


func _ready() -> void:
	# 自動開始播放 BGM
	play_bgm()


# 背景音樂

func play_bgm(fade_in: float = 2.0) -> void:
	if bgm_player.playing:
		return
	
	bgm_player.stream = BGM
	bgm_player.volume_db = -40.0
	bgm_player.play()
	
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -8.0, fade_in)


func stop_bgm(fade_out: float = 1.5) -> void:
	if not bgm_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, fade_out)
	await tween.finished
	bgm_player.stop()


# 音效

func play_pickup() -> void:
	sfx_player.stream = SFX_PICKUP
	sfx_player.play()


func play_code_correct() -> void:
	sfx_player.stream = SFX_CODE_CORRECT
	sfx_player.play()
