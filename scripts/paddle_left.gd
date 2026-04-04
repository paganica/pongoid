extends CharacterBody2D

@export var speed := 350
@onready var collision = $CollisionShape2D
var start_x
var paddle_height

func _ready():
	start_x = position.x
	
	var screen_height = get_viewport_rect().size.y
	paddle_height = screen_height / 8

	collision.shape.size.y = paddle_height

	queue_redraw()

func _draw():
	var width = 20
	draw_rect(Rect2(-width/2, -paddle_height/2, width, paddle_height), Color.BLUE)

func _physics_process(delta):
	var direction = 0
	
	if Input.is_action_pressed("p2_up"):
		direction -= 1
	if Input.is_action_pressed("p2_down"):
		direction += 1

	var screen_height = get_viewport_rect().size.y
	var half_height = paddle_height / 2

	position.y += direction * speed * delta
	position.y = clamp(position.y, half_height + 15, screen_height - half_height - 15)
	position.x = start_x
