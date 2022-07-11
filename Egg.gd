extends RigidBody2D

signal egg_hit(egg, hit_by)

var Flame=preload("res://Flames.tscn")

var rider=""
var bird
var StandingRider=preload("res://StandingRider.tscn")
var flash=1
var hatch_delay=4
var start_flashing=true
var still=0
var mask
var layer


func _ready():
	mask=collision_mask
	layer=collision_layer
	collision_mask=1+16+64+128
	collision_layer=32768
	set_contact_monitor(true)
	$HatchTimer.wait_time=hatch_delay
	if start_flashing:
		$FlashTimer.start()

func start_spin():
	var spin=1000*float(randf()/2-0.25)
	yield (get_tree(),"idle_frame")
	apply_torque_impulse(spin)


	
func _integrate_forces(state):
	var xform = state.get_transform()
	xform.origin.x=wrapf(xform.origin.x, 0, 1024)	
	xform.origin.y=clamp(xform.origin.y,-5,600)
	state.set_transform(xform)

	if state.get_contact_count()==0:
		still=0
	else:
		for i in range(state.get_contact_count() ):
			var b=state.get_contact_collider_object(i)
			var n=state.get_contact_local_normal(i)
			if b.is_in_group("floor") and abs(linear_velocity.y)<1 and abs(linear_velocity.x)<1:
			#abs(n.x)<0.1 and n.y<-0.9:
				#print ("egg touching a floor : "+str(still))
				still+=1
				if still>=2:
					#print("egg stopped")
					sleeping=true
					$HatchTimer.start()
			else:
				#print ("egg touching "+b.name+" " +str(n))
				still=0
		
		
#			if abs(linear_velocity.y)<1 and abs(linear_velocity.x)<1:
#				print("egg stopped")
#				sleeping=true
#				$HatchTimer.start()



func _on_Egg_body_entered(body):
	#print("egg hit by "+body.name)
	if body.is_in_group("player1") or body.is_in_group("player2"):
		#print("egg hit by player")
		emit_signal("egg_hit", self, body)
	if body.is_in_group("flames"):
		#print("egg hit fire!")
		if bird and weakref(bird).get_ref():
			bird.queue_free()
		var p=$".."
		var f=Flame.instance()
		p.add_child(f)
		f.global_position=global_position
		f.global_position.y=$"/root/World/Flames".global_position.y
		f.get_node("Animations").play("flameegg")
		$Animations.play("burnup")

func _on_HatchTimer_timeout():
	var r=StandingRider.instance()
	var p=$".."
	p.add_child(r)
	r.set_rider(rider)
	r.connect("standingrider_hit", p, "standingrider_hit")
	r.bird=bird
	r.global_position=global_position+Vector2(0,12)
	queue_free()
	
func _on_CollideTimer_timeout():
	collision_mask=mask
	collision_layer=layer
	$FlashTimer.stop()
	modulate= Color( 1, 1, 1, 1 )


func _on_FlashTimer_timeout():
	modulate= Color( 1, 1, 1, flash )
	flash=1-flash
