extends Node3D

@export var footstep_sounds : Array[AudioStreamMP3]
@export var ground_pos : Marker3D
@onready var player: CharacterBody3D = get_parent()

func _ready() -> void:
	player.step.connect(play_sound)
	
func play_sound():
	if footstep_sounds.size() == 0:
		print("No footstep sounds assigned!")
		return
		
	var audio_player : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	var random_index : int = randi_range(0, footstep_sounds.size() - 2)  # Fixed range
	audio_player.stream = footstep_sounds[random_index]
	audio_player.pitch_scale = randf_range(0.5, 1.8)  # Fixed property name
	ground_pos.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(func destroy(): audio_player.queue_free())
