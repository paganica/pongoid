extends CharacterBody2D

@export var speed := 0
@export var size_ratio := 60.0
var radius
var last_hitter = null
var is_multiball := false
@onready var collision = $CollisionShape2D

func _ready():
	var screen_height = get_viewport_rect().size.y
	radius = screen_height / size_ratio
	update_collision()
	queue_redraw()
	if not is_multiball:
		speed = get_base_speed()
		velocity = Vector2(-speed, 0)

func _physics_process(delta):
	var col = move_and_collide(velocity * delta)

	if col:
		var collider = col.get_collider()
		if collider.name.begins_with("Paddle"):
			var paddle = collider
			var offset = global_position.y - paddle.global_position.y
			var shape = paddle.get_node("CollisionShape2D").shape
			var half_height = shape.size.y / 2
			var normalized = clamp(offset / half_height, -1.0, 1.0)

			var paddle_influence = clamp(paddle.velocity.y / 350.0, -1.0, 1.0) * 0.4
			var angle_factor = clamp(normalized + paddle_influence, -1.0, 1.0)
			var angle = clamp(abs(angle_factor) * 1.1, 0.2, 1.1) * sign(angle_factor)

			speed += get_speed_increment()
			last_hitter = paddle
			velocity.x = cos(angle) * speed * -sign(velocity.x)
			velocity.y = sin(angle) * speed
		else:
			velocity = velocity.bounce(col.get_normal())

func _draw():
	draw_circle(Vector2.ZERO, radius, Color.WHITE)

func reset(direction):
	speed = get_base_speed()
	last_hitter = null
	var angle = randf_range(-0.3, 0.3)
	velocity = Vector2(cos(angle) * direction, sin(angle)).normalized() * speed

func update_collision():
	collision.shape.radius = radius

func get_base_speed():
	match GameSettings.ai_difficulty:
		"easy":   return 400
		"medium": return 450
		"hard":   return 500
	return 450

func get_speed_increment():
	match GameSettings.ai_difficulty:
		"easy":   return 5
		"medium": return 10
		"hard":   return 10
	return 10
