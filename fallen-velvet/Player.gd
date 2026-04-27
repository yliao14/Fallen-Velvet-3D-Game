extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 3
const MOUSE_SENSITIVITY = 0.0025
const INTERACT_DISTANCE = 3.0

@onready var head = $Head
@onready var ray: RayCast3D = $Head/RayCast3D
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_label: Label = $CanvasLayer/InteractLabel
@onready var crosshair: TextureRect = $CanvasLayer/Crosshair

var pitch = 0.0
var _current_target = null

# 追蹤現在是不是有 UI 開著（inventory/recipe），有的話禁用互動
var is_ui_open: bool = false


func _ready() -> void:
	add_to_group("player")  # ⭐ 加這行
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ray.target_position = Vector3(0, 0, -INTERACT_DISTANCE)
	ray.collision_mask = 2
	interact_label.visible = false


func _input(event: InputEvent) -> void:
	# UI 開著時，禁用滑鼠視角轉動（避免 UI 點擊時鏡頭亂動）
	if event is InputEventMouseMotion and not is_ui_open:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		pitch += event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		head.rotation.x = pitch
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 只有沒開 UI 時，按滑鼠才鎖定鏡頭
	if event is InputEventMouseButton and event.pressed and not is_ui_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# UI 開著時禁用 E 鍵互動
	if event is InputEventKey and event.pressed and event.keycode == KEY_E and not is_ui_open:
		print("E pressed, target: ", _current_target)
		if _current_target and _current_target.has_method("interact"):
			_current_target.interact()


func _physics_process(delta: float) -> void:
	# UI 開著時，凍結移動（更沉浸的體驗）
	if is_ui_open:
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var move_x = 0.0
	var move_z = 0.0
	if Input.is_key_pressed(KEY_D):
		move_x -= 1.0
	if Input.is_key_pressed(KEY_A):
		move_x += 1.0
	if Input.is_key_pressed(KEY_S):
		move_z -= 1.0
	if Input.is_key_pressed(KEY_W):
		move_z += 1.0
	var move_dir = Vector3(move_x, 0, move_z).normalized()
	var direction = (transform.basis * move_dir).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()
	
	_check_raycast()


func _check_raycast() -> void:
	# UI 開著時，不要顯示 raycast label
	if is_ui_open:
		_current_target = null
		interact_label.visible = false
		return
	
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().size / 2
	
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_end = ray_origin + camera.project_ray_normal(screen_center) * INTERACT_DISTANCE
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 0xFFFFFFFF 
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit = result.collider
		_current_target = hit
		
		if hit.has_method("interact"):
			interact_label.visible = true
			# ⭐ MODIFIED: 優先用 prompt_text（從 interactable 來），fallback 才用 item_id
			if "prompt_text" in hit and hit.prompt_text != "":
				interact_label.text = hit.prompt_text
			elif "item_id" in hit:
				interact_label.text = "[E] Pick up " + hit.item_id
			else:
				interact_label.text = "[E] Interact"
		else:
			interact_label.visible = false  # ⭐ NEW: 打到沒有 interact() 的東西就不顯示
	else:
		_current_target = null
		interact_label.visible = false


# 給 UI 系統呼叫，告訴 player 進入 UI 模式
func set_ui_open(opened: bool) -> void:
	is_ui_open = opened
	if opened:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		interact_label.visible = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
