extends Node3D

@onready var audio_player = $AudioStreamPlayer3D

func interact():
	if audio_player:
		audio_player.play()
