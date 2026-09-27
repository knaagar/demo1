extends Area2D

@export var interact_id: String = "newspaper" 
var player_nearby = false

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("ui_accept"):
		var main_scene = get_tree().current_scene
		
		if not main_scene.dialogue_box.visible and not main_scene.newspaper_overlay.visible and main_scene.player.is_physics_processing():
			main_scene.handle_interaction(interact_id)
			get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = true
		get_tree().current_scene.nearby_interactables += 1

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = false
		get_tree().current_scene.nearby_interactables -= 1
