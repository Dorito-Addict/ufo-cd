extends ColorRect

# @export var tweenTime = 0.05

func _ready():
	hide()
func flash(tweenTime):
	var tween = get_tree().create_tween()
	show()
	tween.tween_property(self, "modulate", Color(1,1,1,1), 0)
	tween.tween_property(self, "modulate", Color(1,1,1,1), tweenTime)
	tween.tween_property(self, "modulate", Color(1,1,0,0.66), tweenTime)
	tween.tween_property(self, "modulate", Color(1,0,0,0.66), tweenTime)
	tween.tween_property(self, "modulate", Color(1,0,0,0.0), tweenTime)
