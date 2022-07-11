extends Area2D

signal standingrider_hit(rider, hit_by)

var rider
var bird

var Buzzard=load("res://BirdBuzzard.tscn")

func _ready():
	$AnimationPlayer.play("hatch")
	
func set_rider(r):
	rider=r
	var riders=$Rider.get_children()
	$Rider.hide()
	for r in range(riders.size() ):
		riders[r].hide()
	if r!="":
		$Rider.show()
		get_node("Rider/"+r).show()
	
func _on_RemountTimer_timeout():
	var b=bird
	#$"..".add_child(b)
	b.set_rider(rider)
	b.global_position=global_position+Vector2(0,-20)
	b.target=self
	if b.global_position.x<512:
		b.face(1)
		b.global_position.x=0
	else:
		b.face(-1)
		b.global_position.x=1023
	print("started bird "+b.name+" at "+str(b.global_position))
	#queue_free()

	b.show()
	b.state=b.STATE.FLYING_IN
	b.is_alive=true
	b.add_to_group("npc")

func _on_StandingRider_body_entered(body):
	print("rider hit by "+body.name)
	#queue_free()
	bird.remove=true
	hide()
	global_position.y-=20
	
	emit_signal("standingrider_hit", self, body)
	
