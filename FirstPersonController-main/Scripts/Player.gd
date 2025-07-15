extends CharacterBody3D

var speed
const WALK_SPEED = 3
const SPRINT_SPEED = 5
const JUMP_VELOCITY = 3
const SENSITIVITY = 0.008

# Gamepad camera sensitivity
const GAMEPAD_SENSITIVITY = 2.0
const GAMEPAD_DEADZONE = 0.1

# Enhanced but simple bob variables
const BOB_FREQ = 2.5
const BOB_AMP = 0.11
var t_bob = 0.0

# FOV variables
const BASE_FOV = 85
const FOV_CHANGE = 1.4

# Simple movement smoothing
const MOVEMENT_SMOOTHING = 10.0
const AIR_MOVEMENT_SMOOTHING = 3.0

# Subtle camera tilt when moving
const MOVEMENT_TILT_AMOUNT = 1.4
const TILT_SPEED = 4.0
var current_tilt = 0.0

# Simple momentum for smoother movement
var movement_velocity = Vector3.ZERO
const MOMENTUM_SMOOTHING = 10.0

# Flashlight sway
const SWAY_AMOUNT = 1
const SWAY_SPEED = 3
const MOUSE_SWAY = 0.3
var flashlight_offset = Vector3.ZERO
var mouse_delta = Vector2.ZERO
var flashlight_base_transform: Transform3D

# Grab system
const GRAB_RANGE = 2.5
const GRAB_FORCE = 90
const GRAB_DISTANCE = 3
var grabbed_object = null
var grab_target_pos = Vector3.ZERO

# Flashlight system
var flashlight_enabled = true

var gravity = 10
var can_play : bool = true

signal step

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var flashlight = $Head/Camera3D/SpotLight3D
@onready var flashlight_audio = $Head/FlashlightAudio

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if flashlight:
		flashlight_base_transform = flashlight.transform
		flashlight_enabled = true
		flashlight.visible = flashlight_enabled

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-58), deg_to_rad(80))
		mouse_delta = event.relative

	if Input.is_action_just_pressed("interact"):
		if grabbed_object:
			_release_object()
		else:
			_try_grab_object()
			_try_interact_object()

	if Input.is_action_just_pressed("mouse_left"):
		if grabbed_object:
			_throw_object()
	
	if Input.is_action_just_pressed("flashlight"):
		_toggle_flashlight()

func _physics_process(delta):
	_handle_gamepad_camera(delta)
	_handle_gravity(delta)
	_handle_jumping()
	_handle_smooth_movement(delta)
	_handle_subtle_camera_effects(delta)
	_update_flashlight_sway(delta, Input.get_vector("left", "right", "up", "down"))
	_update_grabbed_object(delta)

	move_and_slide()

func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func _handle_jumping():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _handle_smooth_movement(delta):
	# Determine target speed
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var target_velocity = Vector3.ZERO
	if direction:
		target_velocity = direction * speed
	
	# Smooth movement with different rates for ground vs air
	var smoothing_rate = MOVEMENT_SMOOTHING if is_on_floor() else AIR_MOVEMENT_SMOOTHING
	
	if is_on_floor():
		velocity.x = lerp(velocity.x, target_velocity.x, delta * smoothing_rate)
		velocity.z = lerp(velocity.z, target_velocity.z, delta * smoothing_rate)
	else:
		# Reduced air control for realism
		velocity.x = lerp(velocity.x, target_velocity.x, delta * smoothing_rate)
		velocity.z = lerp(velocity.z, target_velocity.z, delta * smoothing_rate)
	
	# Store movement velocity for camera effects
	movement_velocity = Vector3(velocity.x, 0, velocity.z)

func _handle_subtle_camera_effects(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var velocity_length = movement_velocity.length()
	
	# Subtle camera tilt when moving sideways
	var target_tilt = -input_dir.x * MOVEMENT_TILT_AMOUNT
	current_tilt = lerp(current_tilt, target_tilt, delta * TILT_SPEED)
	camera.rotation.z = deg_to_rad(current_tilt)
	
	# Enhanced headbob with smooth transitions
	t_bob += delta * velocity_length * float(is_on_floor())
	camera.transform.origin = _smooth_headbob(t_bob, velocity_length)

	# Smooth FOV changes
	var velocity_clamped = clamp(velocity_length, 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 6.0)

func _smooth_headbob(time, velocity_length) -> Vector3:
	var pos = Vector3.ZERO
	
	# Scale bob intensity with movement speed
	var intensity = clamp(velocity_length / SPRINT_SPEED, 0.0, 1.0)
	var current_amp = BOB_AMP * intensity
	
	# Smooth vertical bob
	pos.y = sin(time * BOB_FREQ) * current_amp
	
	# Subtle horizontal sway
	pos.x = cos(time * BOB_FREQ / 2) * current_amp * 0.6
	
	# Very subtle forward/back movement
	pos.z = sin(time * BOB_FREQ * 0.3) * current_amp * 0.2

	# Footstep detection (simplified)
	var low_pos = current_amp * 0.7
	if pos.y > -low_pos:
		can_play = true
	if pos.y < -low_pos and can_play and intensity > 0.1:
		can_play = false
		emit_signal("step")

	return pos

func _handle_gamepad_camera(delta):
	var right_stick = Vector2(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	)
	
	if right_stick.length() < GAMEPAD_DEADZONE:
		right_stick = Vector2.ZERO
	else:
		right_stick = right_stick.normalized() * ((right_stick.length() - GAMEPAD_DEADZONE) / (1.0 - GAMEPAD_DEADZONE))
	
	if right_stick.length() > 0:
		head.rotate_y(-right_stick.x * GAMEPAD_SENSITIVITY * delta)
		camera.rotate_x(-right_stick.y * GAMEPAD_SENSITIVITY * delta)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-58), deg_to_rad(80))
		mouse_delta = right_stick * GAMEPAD_SENSITIVITY * 100

func _headbob(time) -> Vector3:
	# Keep original function for compatibility
	return _smooth_headbob(time, movement_velocity.length())

func _update_flashlight_sway(delta, input_dir):
	if not flashlight:
		return

	# Calculate target sway
	var target_sway = Vector3.ZERO
	target_sway.x = -input_dir.x * SWAY_AMOUNT
	target_sway.y = -input_dir.y * SWAY_AMOUNT * 0.5
	target_sway.x += -mouse_delta.x * MOUSE_SWAY
	target_sway.y += mouse_delta.y * MOUSE_SWAY

	# Add subtle movement-based sway
	var velocity_factor = movement_velocity.length() / SPRINT_SPEED
	target_sway.z = velocity_factor * 0.05
	
	# Add very subtle side-to-side sway when moving
	target_sway.x += sin(t_bob * BOB_FREQ) * velocity_factor * 0.3

	# Smooth the sway offset
	flashlight_offset = flashlight_offset.lerp(target_sway, delta * SWAY_SPEED)
	flashlight.transform.origin = flashlight_base_transform.origin + flashlight_offset

	# Smooth rotation sway
	var rotation_sway = Vector3.ZERO
	rotation_sway.z = -input_dir.x * 1.0
	rotation_sway.x = input_dir.y * 0.5
	
	var base_rotation = flashlight_base_transform.basis.get_euler()
	var rotation_sway_rad = Vector3(
		deg_to_rad(rotation_sway.x),
		deg_to_rad(rotation_sway.y),
		deg_to_rad(rotation_sway.z)
	)
	var target_rotation = base_rotation + rotation_sway_rad
	flashlight.rotation = flashlight.rotation.lerp(target_rotation, delta * SWAY_SPEED)

	# Smooth mouse delta dampening
	mouse_delta = mouse_delta.lerp(Vector2.ZERO, delta * 6.0)

func _toggle_flashlight():
	if flashlight:
		flashlight_enabled = !flashlight_enabled
		flashlight.visible = flashlight_enabled
		if flashlight_audio:
			flashlight_audio.play()

func _try_grab_object():
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_transform.origin
	var to = from + camera.global_transform.basis.z * -GRAB_RANGE

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		if collider.has_method("can_be_grabbed") and collider.can_be_grabbed():
			_grab_object(collider)

func _grab_object(object):
	grabbed_object = object
	grab_target_pos = camera.global_transform.origin + camera.global_transform.basis.z * -GRAB_DISTANCE

func _release_object():
	grabbed_object = null

func _throw_object():
	if grabbed_object:
		var throw_direction = -camera.global_transform.basis.z.normalized()
		var throw_force = 20
		grabbed_object.apply_impulse(Vector3.ZERO, throw_direction * throw_force)
		grabbed_object = null

func _update_grabbed_object(delta):
	if grabbed_object:
		grab_target_pos = camera.global_transform.origin + camera.global_transform.basis.z * -GRAB_DISTANCE
		var direction_to_target = (grab_target_pos - grabbed_object.global_transform.origin)
		var force = direction_to_target * GRAB_FORCE
		grabbed_object.apply_central_force(force)
		grabbed_object.linear_velocity *= 0.9

func _try_interact_object():
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_transform.origin
	var to = from + camera.global_transform.basis.z * -GRAB_RANGE

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		if collider and collider.has_method("interact"):
			collider.interact()
