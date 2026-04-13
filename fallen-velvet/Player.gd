extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 3
const MOUSE_SENSITIVITY = 0.0025
const INTERACT_DISTANCE = 3.0

@onready var head = $Head
@onready var ray: RayCast3D = $Head/RayCast3D
@onready var interact_label: Label = $CanvasLayer/InteractLabel
@onready var crosshair: TextureRect = $CanvasLayer/Crosshair

var pitch = 0.0
var _current_target = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ray.target_position = Vector3(0, 0, -INTERACT_DISTANCE)
	ray.collision_mask = 2
	interact_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		pitch += event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		head.rotation.x = pitch

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# 按 E 互動
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if _current_target and _current_target.has_method("interact"):
			_current_target.interact()

func _physics_process(delta: float) -> void:
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

	# Raycast 每幀檢查
	_check_raycast()

func _check_raycast() -> void:
	if ray.is_colliding():
		var hit = ray.get_collider()
		print("hitting: ", hit.name)    # ← 加這行
		
		if hit != _current_target:
			_current_target = hit

		if hit.has_method("interact"):
			interact_label.visible = true
			if "item_id" in hit:
				interact_label.text = "[E] Pick up " + hit.item_id
			else:
				interact_label.text = "[E] Interact"
	else:
		_current_target = null
		interact_label.visible = false
