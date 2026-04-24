extends ParallaxLayer
@onready var clouds3: Sprite2D = $"../ParallaxLayer3/clouds3"

const cloud_speed=-3
const cloud_speed2=-1

func _process(delta):
	if  clouds3:
		self.motion_offset.x+=cloud_speed2 *delta
	else:
		self.motion_offset.x+=cloud_speed *delta
