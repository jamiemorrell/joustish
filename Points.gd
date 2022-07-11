extends Node2D

func set_points(points):
	$Points.text=str(points)
	$AnimationPlayer.play("fade")

func set_points_egg(points):
	$Points.text=str(points)
	$AnimationPlayer.play("fadeegg")
	
func set_points_bird(points):
	$Points.text=str(points)
	$AnimationPlayer.play("fadebird")
	
func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
