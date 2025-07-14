extends Node3D

@export var interact_key := "ui_accept"  # You can map this to "E" in InputMap
@onready var area = $Area3D
@onready var audio_player = $AudioStreamPlayer3D

var player_in_range := false

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta):
	if player_in_range and Input.is_action_just_pressed(interact_key):
		play_interaction_sound()

func _on_body_entered(body):
	if body.name == "Player":  # Change this if your player node has a different name
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func play_interaction_sound():
	if audio_player:
		audio_player.play()
