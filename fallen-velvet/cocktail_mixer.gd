extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var glass_display: Control = $GlassDisplay
@onready var glass_image: TextureRect = $GlassDisplay/GlassImage
@onready var liquid_shape: TextureRect = $GlassDisplay/LiquidShape   
@onready var instructions: Label = $Instructions
@onready var mix_button: Button = $MixButton
@onready var developing_overlay: ColorRect = $DevelopingOverlay
@onready var photo_reveal: TextureRect = $PhotoReveal

# 已加入酒杯的材料追蹤
var added_ingredients: Array[String] = []

# 每個材料對應的「液體混合色」
const INGREDIENT_COLORS: Dictionary = {
	"vodka": Color(0.95, 0.95, 0.85, 0.5),      # 透明微黃（伏特加）
	"tomato": Color(0.7, 0.12, 0.12, 0.85),      # 番茄紅
	"lemon": Color(0.95, 0.85, 0.3, 0.6),        # 檸檬黃
	"pepper": Color(0.25, 0.2, 0.18, 0.7),       # 黑色（撒胡椒讓顏色變濁）
	"celery": Color(0.45, 0.65, 0.3, 0.5),       # 芹菜綠
}

# Bloody Mary 最終色（按 MIX 後變這個顏色）
const FINAL_COLOR: Color = Color(0.55, 0.08, 0.08, 0.95)

var inventory_ui_ref: Node = null
var player: Node = null

# 狀態：是否處於混合模式（玩家可點擊 inventory 材料）
var is_mixing_mode: bool = false


func _ready() -> void:
	add_to_group("cocktail_mixer")
	
	# 一開始全部隱藏
	visible = false
	mix_button.visible = false
	developing_overlay.visible = false
	
	# 液體初始：透明
	liquid_shape.modulate = Color(1, 1, 1, 0)
	
	mix_button.pressed.connect(_on_mix_pressed)
	
	# 監聽 GameManager 事件
	GameManager.cocktail_glass_found.connect(_on_glass_found)
	
	# 抓 reference
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	inventory_ui_ref = get_tree().get_first_node_in_group("inventory_ui")


# 玩家對著酒杯按 E → 進入混合模式
func _on_glass_found() -> void:
	# 確認玩家有 5 個材料齊
	if not _all_ingredients_in_inventory():
		print("⚠️ 還沒蒐集齊 5 個材料")
		return
	
	_start_mixing_mode()


func _all_ingredients_in_inventory() -> bool:
	for item_id in GameManager.ALL_INGREDIENTS:
		if not GameManager.has_item(item_id):
			return false
	return true


func _start_mixing_mode() -> void:
	is_mixing_mode = true
	visible = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # ⭐ 直接釋放 cursor
	
	
	# 通知 inventory UI 進入「可點擊」模式
	if inventory_ui_ref and inventory_ui_ref.has_method("set_clickable_mode"):
		inventory_ui_ref.set_clickable_mode(true)
	
	# 通知 player 釋放滑鼠
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(true)
	
	# 進場動畫：背景淡入 + 酒杯從下方彈入
	background.modulate.a = 0.0
	glass_display.modulate.a = 0.0
	glass_display.position.y += 100
	instructions.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(background, "modulate:a", 1.0, 0.4)
	tween.tween_property(glass_display, "modulate:a", 1.0, 0.5)
	tween.tween_property(glass_display, "position:y", glass_display.position.y - 100, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(instructions, "modulate:a", 1.0, 0.4)


# 玩家點了 inventory 的某個材料 → 由 inventory UI 呼叫這個
func add_ingredient(item_id: String) -> void:
	if item_id in added_ingredients:
		return
	if not is_mixing_mode:
		return
	
	added_ingredients.append(item_id)
	GameManager.add_to_cocktail(item_id)
	
	# 液體顏色混合動畫
	_animate_liquid_color(item_id)
	
	# 全加完了 → 顯示 MIX 按鈕
	if added_ingredients.size() == GameManager.ALL_INGREDIENTS.size():
		_show_mix_button()


# 液體顏色混合：當前色 → 漸變到加入新材料的混合結果
func _animate_liquid_color(item_id: String) -> void:
	var new_color = INGREDIENT_COLORS.get(item_id, Color.WHITE)
	var current_color = liquid_shape.modulate
	
	# 計算混合後的目標顏色
	var mixed_color: Color
	if added_ingredients.size() == 1:
		# 第一個材料：直接用它的顏色
		mixed_color = new_color
	else:
		# 後續材料：跟現有顏色混合
		mixed_color = current_color.lerp(new_color, 0.5)
		# tomato 加進來時強制偏紅（Bloody Mary 應該是紅的）
		if item_id == "tomato":
			mixed_color = current_color.lerp(Color(0.6, 0.1, 0.1, 0.85), 0.7)
	
	# 倒入動畫：modulate 顏色平滑變化
	var tween = create_tween()
	tween.tween_property(liquid_shape, "modulate", mixed_color, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _show_mix_button() -> void:
	mix_button.visible = true
	mix_button.modulate.a = 0.0
	mix_button.scale = Vector2(0.8, 0.8)
	mix_button.pivot_offset = mix_button.size / 2.0
	
	# 提示文字也更新
	instructions.text = "Mix it now."
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(mix_button, "modulate:a", 1.0, 0.5)
	tween.tween_property(mix_button, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 按鈕脈動，吸引點擊
	await tween.finished
	_pulse_mix_button()


func _pulse_mix_button() -> void:
	var pulse = create_tween()
	pulse.set_loops()
	pulse.tween_property(mix_button, "modulate", Color(1.2, 1.2, 1.2), 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(mix_button, "modulate", Color.WHITE, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_mix_pressed() -> void:
	print("🍸 MIX button pressed!")
	
	mix_button.disabled = true
	is_mixing_mode = false
	
	# 通知 inventory 退出可點擊模式
	if inventory_ui_ref and inventory_ui_ref.has_method("set_clickable_mode"):
		inventory_ui_ref.set_clickable_mode(false)
	
	# 通知 GameManager 完成調酒
	GameManager.complete_cocktail()
	
	# 開始底片轉場
	_play_developing_sequence()


func _play_developing_sequence() -> void:
	# 階段 1：液體變濃郁紅 + 按鈕淡出
	var tween1 = create_tween().set_parallel(true)
	tween1.tween_property(liquid_shape, "modulate", FINAL_COLOR, 1.2)
	tween1.tween_property(mix_button, "modulate:a", 0.0, 0.5)
	tween1.tween_property(instructions, "modulate:a", 0.0, 0.5)
	await tween1.finished
	
	# 階段 2：螢幕邊緣紅光浮現
	developing_overlay.visible = true
	developing_overlay.modulate.a = 1.0
	developing_overlay.color = Color(0.349, 0.016, 0.016, 0.0)
	
	var red_tween = create_tween()
	red_tween.tween_property(developing_overlay, "color:a", 0.6, 1.5)
	await red_tween.finished
	
	# 階段 3：紅光氛圍停留
	await get_tree().create_timer(1).timeout
	
	# 階段 4：螢幕全黑
	var black_tween = create_tween()
	black_tween.tween_property(developing_overlay, "color", Color(0, 0, 0, 1.0), 1.5)
	await black_tween.finished
	
	# === 新增階段：底片浮現 ===
	await _reveal_photo()
	
	# 完成
	_finish_level()


func _reveal_photo() -> void:
	glass_display.visible = false
	
	photo_reveal.visible = true
	photo_reveal.modulate = Color(1, 1, 1, 0)
	photo_reveal.scale = Vector2(0.7, 0.7)
	photo_reveal.pivot_offset = photo_reveal.size / 2.0
	
	# 慢速淡入
	var fade_in = create_tween().set_parallel(true)
	fade_in.tween_property(photo_reveal, "modulate:a", 1.0, 2.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(photo_reveal, "scale", Vector2.ONE, 2.0)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	
	# 停留 2 秒
	await get_tree().create_timer(2).timeout
	
	# ⭐ NEW: 底片正要飛走時，inventory 同步顯示底片
	GameManager.grant_photo()
	
	# 底片飛走
	var viewport_size = get_viewport().get_visible_rect().size
	var target_position = Vector2(viewport_size.x - 100, 350)
	
	var fly_tween = create_tween().set_parallel(true)
	fly_tween.tween_property(photo_reveal, "global_position", target_position, 1.0)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fly_tween.tween_property(photo_reveal, "scale", Vector2(0.15, 0.15), 1.0)
	fly_tween.tween_property(photo_reveal, "modulate:a", 0.0, 1.0)
	await fly_tween.finished
	
	photo_reveal.visible = false


func _finish_level() -> void:
	# 釋放 player 控制（PuzzleUI 會在 photo_obtained 時顯示）
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if player and player.has_method("set_ui_open"):
		player.set_ui_open(false)
	
	# 隱藏多餘元素
	background.visible = false
	glass_display.visible = false
	mix_button.visible = false
	instructions.visible = false
	
	# 等 0.5 秒讓 PuzzleUI 浮現
	await get_tree().create_timer(0.5).timeout
	
	# 黑色 overlay 淡出，露出 3D 場景
	var fade = create_tween()
	fade.tween_property(developing_overlay, "modulate:a", 0.0, 1.5)
	await fade.finished
	
	# 完全隱藏 cocktail mixer
	visible = false
	developing_overlay.visible = false
	developing_overlay.modulate.a = 1.0  # 重置
	
	print("🎬 Level 1 完成！進入 Level 2: Find the letters")
