extends Area2D

@onready var collision = $CollisionShape2D

enum BrickType {
	BONUS_LONGER,       # last hitter gets longer paddle
	BONUS_FASTER,       # last hitter gets faster paddle
	HANDICAP_SHORTER,   # opponent gets shorter paddle
	HANDICAP_SLOWER,    # opponent gets slower paddle
	NEUTRAL_MULTIBALL,  # 3 balls
	NEUTRAL_RESET       # both paddles reset to normal
}

const BRICK_COLORS = {
	BrickType.BONUS_LONGER:      Color(0.0, 0.8, 0.0),   # green
	BrickType.BONUS_FASTER:      Color(0.0, 0.6, 1.0),   # light blue
	BrickType.HANDICAP_SHORTER:  Color(1.0, 0.4, 0.0),   # orange
	BrickType.HANDICAP_SLOWER:   Color(0.8, 0.0, 0.8),   # purple
	BrickType.NEUTRAL_MULTIBALL: Color(1.0, 1.0, 0.0),   # yellow
	BrickType.NEUTRAL_RESET:     Color(1.0, 1.0, 1.0)    # white
}

var brick_width: float
var brick_height: float

var brick_type: BrickType

func _ready():
	brick_width = get_viewport_rect().size.x / 40.0
	brick_height = get_viewport_rect().size.y / 12.0
	#brick_type = randi() % BrickType.size() as BrickType
	brick_type = BrickType.NEUTRAL_MULTIBALL
	 # sync collision shape to actual brick size
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(brick_width, brick_height)
	queue_redraw()

func _draw():
	var color = BRICK_COLORS[brick_type]
	draw_rect(Rect2(-brick_width / 2, -brick_height / 2, brick_width, brick_height), color)
	# draw label hint
	draw_rect(Rect2(-brick_width / 2, -brick_height / 2, brick_width, brick_height), Color(1, 1, 1, 0.15))

func _on_body_entered(body):
	if body.name == "Ball":
		get_parent().brick_hit(self)
		queue_free()
