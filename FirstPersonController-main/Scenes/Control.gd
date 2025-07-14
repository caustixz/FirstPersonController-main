extends Control

@onready var gun_sprite = $GunSprite
@onready var muzzle_flash = $MuzzleFlash
@onready var fire_timer = $FireTimer

var idle_texture: Texture2D
var fire_texture: Texture2D
var muzzle_flash_texture: Texture2D

func _ready():
	# Load your gun sprites here
	# idle_texture = load("res://sprites/gun_idle.png")
	# fire_texture = load("res://sprites/gun_fire.png")
	# muzzle_flash_texture = load("res://sprites/muzzle_flash.png")
	
	# Set up initial state
	if gun_sprite:
		gun_sprite.texture = idle_texture
	if muzzle_flash:
		muzzle_flash.visible = false
	
	# Connect timer
	if fire_timer:
		fire_timer.timeout.connect(_on_fire_timer_timeout)

func fire_animation():
	if gun_sprite and fire_texture:
		gun_sprite.texture = fire_texture
	
	if muzzle_flash and muzzle_flash_texture:
		muzzle_flash.texture = muzzle_flash_texture
		muzzle_flash.visible = true
	
	# Add some screen shake or recoil effect here if desired
	_add_recoil()
	
	# Reset after short delay
	if fire_timer:
		fire_timer.wait_time = 0.1
		fire_timer.start()

func _on_fire_timer_timeout():
	if gun_sprite and idle_texture:
		gun_sprite.texture = idle_texture
	if muzzle_flash:
		muzzle_flash.visible = false

func _add_recoil():
	# Simple recoil animation
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -5), 0.05)
	tween.tween_property(self, "position", position, 0.15)
