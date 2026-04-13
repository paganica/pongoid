extends CharacterBody2D

var speed := 0.0
var radius := 0.0
@onready var collision = $CollisionShape2D
var last_hitter = null

func _ready():
	update_collision()
	queue_redraw()
	# velocity and speed are set externally before add_child via set_deferred or direct

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
			speed += 10.0
			last_hitter = paddle
			velocity.x = cos(angle) * speed * -sign(velocity.x)
			velocity.y = sin(angle) * speed
		else:
			velocity = velocity.bounce(col.get_normal())

func _draw():
	draw_circle(Vector2.ZERO, radius, Color.WHITE)

func update_collision():
	collision.shape.radius = radius
