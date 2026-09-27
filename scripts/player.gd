extends CharacterBody2D

@export var speed := 60.0
#@export var gravity := 500.0
@onready var sprite = $AnimatedSprite2D
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	velocity.y = 0
	if direction != 0:
		sprite.play("walk")
		if direction < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	else:
		sprite.play("idle")
	#if not is_on_floor():
		#velocity.y += gravity * delta

	move_and_slide()
	global_position.x = clamp(global_position.x, 10, 1060)
