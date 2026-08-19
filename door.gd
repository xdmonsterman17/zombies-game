extends StaticBody3D

@export var cost: int = 500
@export var rooms_to_unlock: Array[NodePath]

@onready var interaction_area: Area3D = $InteractionArea

func _ready() -> void:
	# Ensure the interaction area only detects players
	interaction_area.collision_mask = 1 # Assuming players are on layer 1

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	# Check if the player presses the interact button (e.g., "F" or "Square")
	if event.is_action_pressed("interact"):
		_try_buy_door()

func _try_buy_door() -> void:
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	var local_player = null
	
	for body in overlapping_bodies:
		# Find if our local player is in the zone
		if body.is_in_group("players") and body.is_multiplayer_authority():
			local_player = body
			break
			
	if local_player:
		# TODO: Check if local_player has enough points, and deduct them here
		
		# Tell the server to open the door for everyone
		_open_door.rpc()

@rpc("any_peer", "call_local", "reliable")
func _open_door() -> void:
	# 1. Update the metadata for the linked rooms
	for path in rooms_to_unlock:
		var room = get_node_or_null(path)
		if room:
			room.set_meta("unlocked", true)
			print("Unlocked room: ", room.name)
	
	# 2. Remove the door so players and zombies can pass
	queue_free()
