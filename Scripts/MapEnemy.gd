# MapEnemy.gd
# Attach this script to the root Area2D node of an enemy on the world map.

extends Area2D

## An array of CharacterStats resources that defines the enemies in this encounter.
## You can drag and drop your .tres files here in the Godot editor.
@export var enemies_in_encounter: Array[CharacterStats]

## The background texture for the battle scene.
@export var battle_background: Texture2D


func _ready():
	# Connect the body_entered signal to our custom function.
	# This will fire when a PhysicsBody2D enters the Area2D.
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	# Check if the entering body is the player by checking its group.
	if body.is_in_group("Player"):
		
		# Ensure that enemy data has been assigned to prevent errors.
		if enemies_in_encounter.is_empty():
			print("Warning: This enemy on the map has no encounter data assigned!")
			return

		print("Player has entered the encounter zone. Starting battle...")
		
		# Prepare the complete encounter data package.
		var encounter_data = {
			"enemies": enemies_in_encounter,
			"background": battle_background
		}
		
		# Get the player's position to return to after the battle.
		var player_position = body.global_position
		
		# Call the global GameManager to initiate the battle.
		GameManager.start_battle(encounter_data)
		# player position?
		
		# The enemy is removed from the map after the encounter.
		# You could also play an animation here before it disappears.
		queue_free()
