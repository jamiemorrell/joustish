extends Node2D

var busy=false

func _ready():
	$Timer.wait_time=2+randi()%3
	$Timer.start()

func flameloop_on():
	$Timer.stop()
	global_position.y=$"/root/World/PlayArea/Fire".margin_top+1
	busy=true
	$Animations.playback_speed=1.0
	$Animations.play("flameloop")

func set_busy():
	$Timer.stop()
	busy=true
	
func remove():
	$Timer.stop()
	print("remove flame")
	queue_free()
	
func stop():
	$Animations.play("flame")
	busy=false
	$Timer.start()
	
func _on_Timer_timeout():
	if !busy:
		global_position.y=$"/root/World/PlayArea/Fire".margin_top+1
		if randi()%2==0:
			global_position.x=10+randi()%165
		else:
			global_position.x=820+randi()%(1014-820)
		$Sprite.show()
		$Animations.playback_speed=0.8+(randf()*0.4)
		$Animations.play("flame")
		#yield($Animations, "animation_finished")
	$Timer.wait_time=1+randi()%3
	$Timer.start()	

