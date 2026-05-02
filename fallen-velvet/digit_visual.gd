extends Label3D

var is_lit: bool = false
var is_recorded: bool = false

var player: Node = null
var flashlight: SpotLight3D = null

@export var detection_distance: float = 5.0
@export var detection_angle: float = 25.0

# Debug
var debug_print_timer: float = 0.0


func _ready() -> void:
	modulate = Color(1, 1, 1, 0)
	print("📍 DigitVisual ready: ", text)
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	print("   player = ", player)
	
	if player:
		flashlight = player.get_node_or_null("Head/Camera3D/SpotLight3D")
		print("   flashlight = ", flashlight)


func _process(delta: float) -> void:
	if is_recorded:
		return
	
	# Debug 每 1 秒印一次
	debug_print_timer += delta
	var should_debug = debug_print_timer >= 1.0
	if should_debug:
		debug_print_timer = 0.0
	
	if not flashlight:
		if should_debug:
			print(" no flashlight reference")
		_set_lit(false)
		return
	
	if not flashlight.visible:
		if should_debug:
			print("flashlight not visible (turned off)")
		_set_lit(false)
		return
	
	var to_digit = global_position - flashlight.global_position
	var distance = to_digit.length()
	
	if should_debug:
		print("   distance = ", distance, " | threshold = ", detection_distance)
	
	if distance > detection_distance:
		_set_lit(false)
		return
	
	var flashlight_forward = -flashlight.global_transform.basis.z
	var angle = rad_to_deg(flashlight_forward.angle_to(to_digit.normalized()))
	
	if should_debug:
		print("   angle = ", angle, " | threshold = ", detection_angle)
	
	if angle <= detection_angle:
		_set_lit(true)
	else:
		_set_lit(false)


func _set_lit(lit: bool) -> void:
	if is_lit == lit:
		return
	is_lit = lit
	print(" set_lit: ", lit, " | digit = ", text)
	
	var target_alpha = 1.0 if lit else 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", target_alpha, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_recorded() -> void:
	is_recorded = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.4, 1.0, 0.5, 1.0), 0.5)
