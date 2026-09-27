extends Node2D

var current_day: int = 1
var has_key: bool = false
var visited_bakery_day2: bool = false
var storm_active: bool = false
var current_dialogue_lines: Array = []

@onready var audio_paper = $Audio/Paper
@onready var audio_door = $Audio/Door
@onready var audio_storm = $Audio/Storm
@onready var audio_braam = $Audio/Braam

@onready var player = $World/Player
@onready var dialogue_box = $Overlays/DialogueBox
@onready var dialogue_label = $Overlays/DialogueBox/Label 
@onready var newspaper_overlay = $Overlays/NewspaperOverlay
@onready var newspaper_texture_rect = $Overlays/NewspaperOverlay/TextureRect
@onready var inn_guy = $World/InnGuy
@onready var fade_screen = $Overlays/FadeScreen 
@onready var day_text_label = $Overlays/FadeScreen/DayText
@onready var background_anim = $World/Background/BackgroundLayer 

@onready var storm_particles = $World/StormParticles
@onready var world_modulate = $World/WorldModulate

@export var paper_day1: Texture2D
@export var paper_day2: Texture2D
@export var paper_day3: Texture2D
@onready var interact_prompt = $Overlays/InteractPrompt
var nearby_interactables: int = 0

func _ready() -> void:
	fade_screen.color.a = 1.0 
	start_day()

func start_day():
	dialogue_box.visible = false
	newspaper_overlay.visible = false
	player.set_physics_process(false)
	
	match current_day:
		1:
			storm_particles.emitting = false
			world_modulate.color = Color(1, 1, 1)
			background_anim.play("day1")
			player.global_position = $World/Spawns/BakerySpawn.global_position
			inn_guy.visible = true
			play_day_intro(["Welcome to Northester.", "It was a long travel.", "You should find a room."])
		2:
			background_anim.play("day2")
			player.global_position = $World/Spawns/InnSpawn.global_position
			inn_guy.visible = false
			play_day_intro(["Good morning.", "Hope you had a great rest.", "Let's get breakfast."])
		3:
			storm_particles.emitting = false
			audio_storm.stop()
			world_modulate.color = Color(0.5, 0.5, 0.6)
			background_anim.play("day2")
			player.global_position = $World/Spawns/InnSpawn.global_position
			play_day_intro(["It was a massive storm yesterday...", "but it's a new day."])

func play_day_intro(lines: Array):
	fade_screen.color.a = 1.0 
	day_text_label.modulate.a = 0.0 
	
	var tween = create_tween()
	for line in lines:
		tween.tween_callback(func(): day_text_label.text = line)
		tween.tween_property(day_text_label, "modulate:a", 1.0, 1.0)
		tween.tween_interval(1.5)
		tween.tween_property(day_text_label, "modulate:a", 0.0, 1.0)
		tween.tween_interval(0.5)
	
	tween.tween_property(fade_screen, "color:a", 0.0, 1.5)
	tween.tween_callback(func(): player.set_physics_process(true))

func handle_interaction(id: String):
	match id:
		"newspaper":
			if current_day == 2 and not visited_bakery_day2:
				show_dialogue(["I should get my breakfast first."])
			else:
				open_newspaper()
		"inn_guy":
			if current_day == 1:
				show_dialogue([
					"You: Looking for a room for the night.",
					"Bel Inn Owner: 100 a night. Here's the key.",
					"Bel Inn Owner: Try to stay indoors and ignore the wind, it gets crazy this time of year."
				])
				has_key = true
		"inn_door":
			if current_day == 1:
				if has_key:
					audio_door.play()
					advance_day() 
				else:
					audio_door.play()
					show_dialogue(["The door is locked. I should talk to the owner."])
			elif current_day == 2:
				if storm_active:
					audio_door.play()
					advance_day()
				else:
					audio_door.play()
					show_dialogue(["I'm not tired yet. I should check the town."])
			elif current_day == 3:
				audio_door.play()
				show_dialogue(["It's locked from the inside."])
		"bakery":
			if current_day == 1:
				audio_door.play()
				show_dialogue(["It is apparently locked."])
			elif current_day == 2:
				if not visited_bakery_day2:
					audio_door.play()
					show_dialogue([
						"You: Hi, I'd like a loaf of bread.",
						"Chef: We're out of fresh bread but take this day-old loaf.",
						"Chef: Have you seen John from the coffeehouse? He didn't come by today.",
						"You: I don't know him. I'm new in town."
					])
					visited_bakery_day2 = true
				else:
					show_dialogue(["Chef: We are completely sold out."])

func open_newspaper():
	audio_paper.play()
	newspaper_overlay.visible = true
	player.set_physics_process(false)
	
	if current_day == 1:
		newspaper_texture_rect.texture = paper_day1
	elif current_day == 2:
		newspaper_texture_rect.texture = paper_day2
	elif current_day == 3:
		newspaper_texture_rect.texture = paper_day3

func trigger_storm():
	storm_active = true
	storm_particles.emitting = true
	world_modulate.color = Color(0.5, 0.5, 0.6)
	audio_storm.play()
	show_dialogue(["Snow all of a sudden!?!? I need to get back inside."])

func show_dialogue(lines: Array):
	current_dialogue_lines = lines
	next_dialogue_line()

func next_dialogue_line():
	if current_dialogue_lines.size() > 0:
		dialogue_label.text = current_dialogue_lines.pop_front()
		dialogue_box.visible = true
		player.set_physics_process(false)
	else:
		dialogue_box.visible = false
		player.set_physics_process(true)
		if current_day == 2 and storm_active and dialogue_box.visible == false:
			pass

func advance_day():
	player.set_physics_process(false)
	var tween = create_tween()
	tween.tween_property(fade_screen, "color:a", 1.0, 1.5)
	
	tween.tween_callback(func(): 
		current_day += 1
		has_key = false
		start_day()
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		if newspaper_overlay.visible:
			audio_paper.play()
			newspaper_overlay.visible = false
			player.set_physics_process(true)
			get_viewport().set_input_as_handled()
			
			if current_day == 2 and visited_bakery_day2 and not storm_active:
				trigger_storm()
			elif current_day == 3:
				trigger_ending()
				
		elif dialogue_box.visible:
			next_dialogue_line() 
			get_viewport().set_input_as_handled()

func trigger_ending():
	player.set_physics_process(false)
	background_anim.play("day3")
	audio_braam.play()
	var tween = create_tween()
	tween.tween_interval(2.5) 
	tween.tween_property(fade_screen, "color:a", 1.0, 1.0)
	tween.tween_callback(func():
		day_text_label.text = "Northester"
		day_text_label.modulate.a = 0.0
	)
	tween.tween_property(day_text_label, "modulate:a", 1.0, 1.0)
	tween.tween_interval(1.5)
	tween.tween_property(day_text_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		day_text_label.text = "Launching Soon."
		day_text_label.modulate.a = 0.0
	)
	tween.tween_property(day_text_label, "modulate:a", 1.0, 1.0)
	tween.tween_interval(1.5)
	tween.tween_property(day_text_label, "modulate:a", 0.0, 1.0)
	
	tween.tween_callback(func():
		day_text_label.text = ""
	)

func _process(delta: float) -> void:
	if nearby_interactables > 0 and not dialogue_box.visible and not newspaper_overlay.visible and player.is_physics_processing() and current_day < 4:
		interact_prompt.visible = true
	else:
		interact_prompt.visible = false
