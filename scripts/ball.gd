extends CharacterBody2D

@export var speed := 0
@export var size_ratio := 60.0  # bigger number = smaller ball
var radius
@onready var collision = $CollisionShape2D

func _ready():
	var screen_height = get_viewport_rect().size.y
	radius = screen_height / size_ratio
	speed = get_base_speed()
	update_collision()
	queue_redraw()
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
			var normalized = offset / half_height
			normalized = clamp(normalized, -1, 1)

			velocity.x = -velocity.x
			velocity.y = normalized * speed
			speed += get_speed_increment()
			velocity = velocity.normalized() * speed
		else:
			velocity = velocity.bounce(col.get_normal())

func _draw():
	draw_circle(Vector2.ZERO, radius, Color.WHITE)
	
func reset(direction):
	speed = get_base_speed()
	var angle = randf_range(-0.5, 0.5)
	velocity = Vector2(direction, angle).normalized() * speed
	
func update_collision():
	collision.shape.radius = radius
	
func get_base_speed():
	match GameSettings.ai_difficulty:
		"easy":
			return 400
		"medium":
			return 450
		"hard":
			return 500
	return 450
	
func get_speed_increment():
	match GameSettings.ai_difficulty:
		"easy":
			return 5
		"medium":
			return 10
		"hard":
			return 10
	return 10
