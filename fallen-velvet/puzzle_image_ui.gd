extends CanvasLayer

@onready var background: TextureRect = $Background
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var puzzle_area: Control = $PuzzleArea
@onready var target_outline: TextureRect = $PuzzleArea/TargetOutline
@onready var pieces_container: Control = $PuzzleArea/PiecesContainer
@onready var close_button: Button = $CloseButton

# 7 個拼圖塊
@onready var pieces: Array[TextureRect] = [
	$PuzzleArea/PiecesContainer/Piece_0,
	$PuzzleArea/PiecesContainer/Piece_1,
	$PuzzleArea/PiecesContainer/Piece_2,
	$PuzzleArea/PiecesContainer/Piece_3,
	$PuzzleArea/PiecesContainer/Piece_4,
	$PuzzleArea/PiecesContainer/Piece_5,
	$PuzzleArea/PiecesContainer/Piece_6,
]

# === Snap 設定 ===
@export var snap_threshold: float = 60.0   # 距離正確位置幾 px 內會被吸住
@export var return_speed: float = 0.4      # 拖錯反彈時間

# === 狀態 ===
var pieces_correct: Array[bool] = [false, false, false, false, false, false, false]
var dragging_piece: TextureRect = null
var drag_offset: Vector2 = Vector2.ZERO

# 每個 piece 的「正確位置」（會在 _ready 自動算 — 因為每張 PNG 都是全畫布大小，正確位置就是 (0,0)）
var correct_positions: Array[Vector2] = []

# 每個 piece 的「散落初始位置」（隨機）
var scatter_positions: Array[Vector2] = []

var player: Node = null


func _ready() -> void:
	add_to_group("puzzle_image_ui")
	visible = false
	
	close_button.pressed.connect(_on_close_pressed)
	
	# 因為每張 PNG 都是全畫布尺寸 → 正確位置都是 (0, 0)
	# 但為了 robust，記錄每個 piece 的初始 position（在 editor 裡你已經設好的）
	for piece in pieces:
		correct_positions.append(Vector2.ZERO)  # 全部歸零（疊在 (0,0)）
	
	# 計算散落初始位置（隨機在 puzzle area 四周）
	_generate_scatter_positions()
	
	# 為每個 piece 加入 input 事件
	for i in range(pieces.size()):
		var piece = pieces[i]
		piece.mouse_filter = Control.MOUSE_FILTER_STOP
		piece.gui_input.connect(_on_piece_input.bind(i))
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


func _generate_scatter_positions() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var puzzle_size = puzzle_area.size
	
	var puzzle_left = -puzzle_size.x / 2.0
	var puzzle_right = puzzle_size.x / 2.0
	var puzzle_top = -puzzle_size.y / 2.0
	var puzzle_bottom = puzzle_size.y / 2.0
	
	var center_margin = 80.0
	
	# 7 個散落位置（拼圖區四周）
	var positions_pool: Array[Vector2] = [
		# 左側 3 個
		Vector2(puzzle_left - 200 - center_margin, puzzle_top + 100),
		Vector2(puzzle_left - 200 - center_margin, 100),
		Vector2(puzzle_left - 200 - center_margin, puzzle_bottom - 250),
		# 右側 3 個
		Vector2(puzzle_right + center_margin, puzzle_top + 100),
		Vector2(puzzle_right + center_margin, 100),
		Vector2(puzzle_right + center_margin, puzzle_bottom - 250),
		# 上方 1 個
		Vector2(0, puzzle_top - 200 - center_margin),
	]
	
	# Clamp 到 viewport 內
	var puzzle_center = puzzle_area.global_position + puzzle_area.size / 2.0
	var screen_margin = 100.0
	
	for i in range(positions_pool.size()):
		var global_pos = puzzle_center + positions_pool[i]
		global_pos.x = clamp(global_pos.x, screen_margin, viewport_size.x - screen_margin)
		global_pos.y = clamp(global_pos.y, screen_margin, viewport_size.y - screen_margin)
		positions_pool[i] = global_pos - puzzle_center
	
	positions_pool.shuffle()
	scatter_positions = positions_pool


# 公開 API：給 PuzzleTrigger 呼叫來開啟拼圖
func open_puzzle() -> void:
	visible = true
	
	# 釋放 cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 通知 player 進 UI 模式
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(true)
	
	# 把每個 piece 移到散落位置（如果還沒拼對）
	for i in range(pieces.size()):
		if not pieces_correct[i]:
			pieces[i].position = scatter_positions[i]
	
	# 進場淡入
	dim_overlay.modulate.a = 0.0
	background.modulate.a = 0.0
	puzzle_area.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 1.0, 0.4)
	tween.tween_property(background, "modulate:a", 0.6, 0.4)
	tween.tween_property(puzzle_area, "modulate:a", 1.0, 0.6)


func _on_close_pressed() -> void:
	close_puzzle()


func close_puzzle() -> void:
	# 已經拼完了就不關（讓完成動畫跑完）
	if _is_all_correct():
		return
	
	# 個別淡出，不用 self.modulate
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_property(background, "modulate:a", 0.0, 0.3)
	tween.tween_property(puzzle_area, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	visible = false
	
	# 重置 alpha 給下次打開用
	dim_overlay.modulate.a = 1.0
	background.modulate.a = 1.0
	puzzle_area.modulate.a = 1.0
	
	# 鎖回 cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(false)

# === Piece 拖動處理 ===

func _on_piece_input(event: InputEvent, piece_index: int) -> void:
	# 已經拼對的 piece 不能再拖
	if pieces_correct[piece_index]:
		return
	
	var piece = pieces[piece_index]
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 開始拖
				dragging_piece = piece
				drag_offset = piece.global_position - get_viewport().get_mouse_position()
				
				# 把這塊 piece 提到最上層（不被其他 piece 蓋住）
				pieces_container.move_child(piece, -1)
			else:
				# 放開拖
				if dragging_piece == piece:
					_check_snap(piece_index)
					dragging_piece = null


func _process(_delta: float) -> void:
	if dragging_piece:
		dragging_piece.global_position = get_viewport().get_mouse_position() + drag_offset


# 檢查放開時是不是在正確位置附近
func _check_snap(piece_index: int) -> void:
	var piece = pieces[piece_index]
	var correct_pos = correct_positions[piece_index]
	var current_pos = piece.position
	
	var distance = current_pos.distance_to(correct_pos)
	
	if distance < snap_threshold:
		# 吸附到正確位置
		_snap_to_correct(piece_index)
	else:
		# 反彈回散落位置
		_return_to_scatter(piece_index)


func _snap_to_correct(piece_index: int) -> void:
	var piece = pieces[piece_index]
	pieces_correct[piece_index] = true
	
	# 平滑吸附到正確位置
	var tween = create_tween()
	tween.tween_property(piece, "position", correct_positions[piece_index], 0.2)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 微微閃光（吸附爽感）
	var flash_tween = create_tween()
	flash_tween.tween_property(piece, "modulate", Color(1.5, 1.5, 1.3), 0.1)
	flash_tween.tween_property(piece, "modulate", Color.WHITE, 0.3)
	
	await tween.finished
	
	# 已經拼對的不接收 input
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 檢查是否全部完成
	if _is_all_correct():
		_on_puzzle_completed()


func _return_to_scatter(piece_index: int) -> void:
	var piece = pieces[piece_index]
	
	# 反彈回散落位置
	var tween = create_tween()
	tween.tween_property(piece, "position", scatter_positions[piece_index], return_speed)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _is_all_correct() -> bool:
	for correct in pieces_correct:
		if not correct:
			return false
	return true


func _on_puzzle_completed() -> void:
	# 隱藏拖拉用的提示輪廓
	var fade_outline = create_tween()
	fade_outline.tween_property(target_outline, "modulate:a", 0.0, 0.5)
	
	# 7 塊一起閃爍 3 次
	for i in range(3):
		var flash = create_tween().set_parallel(true)
		for piece in pieces:
			flash.tween_property(piece, "modulate", Color(1.6, 1.4, 1.0), 0.2)
		await flash.finished
		
		var unflash = create_tween().set_parallel(true)
		for piece in pieces:
			unflash.tween_property(piece, "modulate", Color.WHITE, 0.2)
		await unflash.finished
	
	# 玩家凝視 1.5 秒
	await get_tree().create_timer(1.5).timeout
	
	# 通知 GameManager
	GameManager.complete_puzzle_image()
	
	# 整個 UI 淡出（個別元素淡出）
	var fade = create_tween().set_parallel(true)
	fade.tween_property(dim_overlay, "modulate:a", 0.0, 1.0)
	fade.tween_property(background, "modulate:a", 0.0, 1.0)
	fade.tween_property(puzzle_area, "modulate:a", 0.0, 1.0)
	await fade.finished
	
	visible = false
	
	# 重置（給下次打開用）
	dim_overlay.modulate.a = 1.0
	background.modulate.a = 1.0
	puzzle_area.modulate.a = 1.0
	
	# 鎖回 cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(false)
