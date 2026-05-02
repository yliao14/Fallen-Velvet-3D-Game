extends Control

# 要載入的目標場景路徑
@export var target_scene_path: String = "res://main_game.tscn"

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var loading_label: Label = $LoadingLabel
@onready var hint_label: Label = $HintLabel

var start_time: int = 0

var loading_messages: Array[String] = [
	"Entering the bar...",
	"Pouring drinks...",
	"Setting the mood...",
	"Dimming the lights...",
]


func _ready() -> void:
	var start_time = Time.get_ticks_msec()
	progress_bar.value = 0.0
	loading_label.text = loading_messages[0]
	
	
	# 開始背景載入
	ResourceLoader.load_threaded_request(target_scene_path)
	
	# 開始輪詢進度
	_poll_loading_progress()


func _poll_loading_progress() -> void:
	while true:
		var progress: Array = []
		var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
		
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# 更新進度條 (0.0 ~ 1.0)
				var pct = progress[0] if progress.size() > 0 else 0.0
				progress_bar.value = pct * 100.0
				_update_message(pct)
			
			ResourceLoader.THREAD_LOAD_LOADED:
				# 完成
				progress_bar.value = 100.0
				await get_tree().create_timer(0.5).timeout  # 讓玩家看到 100%
				_finish_loading()
				return
			
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load: " + target_scene_path)
				return
			
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Invalid resource: " + target_scene_path)
				return
		
		# 每幀檢查一次
		await get_tree().process_frame


func _update_message(pct: float) -> void:
	# 根據進度切換訊息
	var idx = int(pct * loading_messages.size())
	idx = clamp(idx, 0, loading_messages.size() - 1)
	loading_label.text = loading_messages[idx]


func _finish_loading() -> void:
	var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
	var min_duration = 2.0
	if elapsed < min_duration:
		await get_tree().create_timer(min_duration - elapsed).timeout
	
	var loaded_resource = ResourceLoader.load_threaded_get(target_scene_path)
	get_tree().change_scene_to_packed(loaded_resource)
