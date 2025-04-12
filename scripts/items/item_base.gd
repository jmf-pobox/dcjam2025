extends Area2D

class_name ItemBase

enum ItemType { WEAPON, ARMOR, POTION, KEY }

@export var item_name: String = "Item"
@export var item_description: String = "A mysterious item."
@export var item_type: ItemType = ItemType.WEAPON
@export var item_value: int = 10
@export var texture: Texture2D

func _ready():
	$Sprite2D.texture = texture

# Called when player interacts with item
func interact(player):
	match item_type:
		ItemType.WEAPON:
			# Equip weapon
			player.equip_weapon(self)
		ItemType.ARMOR:
			# Equip armor
			player.equip_armor(self)
		ItemType.POTION:
			# Use potion
			player.use_potion(self)
		ItemType.KEY:
			# Add key to inventory
			player.add_key(self)
	
	# Remove item from world
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Show interaction prompt
		pass

func _on_body_exited(body):
	if body.is_in_group("player"):
		# Hide interaction prompt
		pass
