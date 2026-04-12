extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 3
const MOUSE_SENSITIVITY = 0.0025

@onready var head = $Head

var pitch = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# 左右转身体
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		
		# 上下转头
		pitch += event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		head.rotation.x = pitch

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
