extends Node3D

class_name WallTorch

# Animation settings
@export var animation_fps: float = 6.0
@export var sprite_frames: int = 3

# Light settings
@export var light_color: Color = Color(1.0, 0.7, 0.3, 1.0)
@export var light_energy: float = 1.5
@export var light_range: float = 6.0
@export var flicker_amount: float = 0.2

# Animation variables
var current_frame: int = 0
var frame_time: float = 0.0
var sprite: Sprite3D
var light: OmniLight3D

func _ready():
	# Create the sprite
	sprite = Sprite3D.new()
	sprite.name = "TorchSprite"
	sprite.texture = preload("res://assets/sprites/torch.png")
	sprite.pixel_size = 0.01
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Configure sprite to use spritesheet
	var sprite_region = Rect2(0, 0, sprite.texture.get_width() / sprite_frames, sprite.texture.get_height())
	sprite.region_enabled = true
	sprite.region_rect = sprite_region
	
	# Adjust sprite position
	sprite.position = Vector3(0, 0.2, 0)
	add_child(sprite)
	
	# Create the light
	light = OmniLight3D.new()
	light.name = "TorchLight"
	light.light_color = light_color
	light.light_energy = light_energy
	light.omni_range = light_range
	light.position = Vector3(0, 0.2, 0.3) # Position light in front of the wall
	light.shadow_enabled = true
	add_child(light)

func _process(delta):
	# Update animation
	frame_time += delta
	if frame_time >= 1.0 / animation_fps:
		frame_time = 0.0
		current_frame = (current_frame + 1) % sprite_frames
		
		# Update sprite region to show correct frame
		var frame_width = sprite.texture.get_width() / sprite_frames
		sprite.region_rect = Rect2(current_frame * frame_width, 0, frame_width, sprite.texture.get_height())
	
	# Add flicker effect to light
	light.light_energy = light_energy * (1.0 + (randf() * flicker_amount - flicker_amount/2.0))
