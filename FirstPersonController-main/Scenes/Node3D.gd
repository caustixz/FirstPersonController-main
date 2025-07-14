extends Node3D

@export var flashlight_on_sound : AudioStreamMP3
@export var flashlight_off_sound : AudioStreamMP3
@export var toggle_key : String = "flashlight"  # Set this in input map

@onready var flashlight : SpotLight3D = get_parent().get_node("Head/Camera3D/SpotLight3D")
@onready var audio_player : AudioStreamPlayer3D = AudioStreamPlayer3D.new()

var flashlight_enabled : bool = true

func _ready():
	# Add audio player to scene
	add_child(audio_player)
	
	# Set up audio player
	audio_player.max_distance = 5.0
	audio_player.volume_db = -5.0

func _input(event):
	if event is InputEventKey and event.keycode == KEY_F and event.pressed:
		toggle_flashlight()

func toggle_flashlight():
	flashlight_enabled = !flashlight_enabled
	
	# Toggle the light
	flashlight.visible = flashlight_enabled
	
	# Play appropriate sound
	if flashlight_enabled:
		if flashlight_on_sound:
			audio_player.stream = flashlight_on_sound
			audio_player.play()
	else:
		if flashlight_off_sound:
			audio_player.stream = flashlight_off_sound
			audio_player.play()

# Optional: Function to turn on/off from other scripts
func set_flashlight(enabled: bool):
	if flashlight_enabled != enabled:
		toggle_flashlight()
