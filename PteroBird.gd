extends KinematicBody2D

var velocity : Vector2 = Vector2(200,0)
var onscreen : bool =false
var started : bool =false
var facing : int = 1
var time_to_change : float = 0.6
var speed : float = 200
var players = []
var flying_out : bool = false
var dying : bool = false
var see_distance : int = 600

func _ready():
	#hide()
	pass


func face(f : int):
	f=sign(f)
	if f!=facing:
		scale.x*=-1
#		$"../Mouth".scale.x*=-1
		#velocity.x*=-1
	facing=sign(f)

func wrapped_distance(o1,o2):
	var p1=o1.global_position
	var p2=o2.global_position
	var half_screen=Global.screen_size.x/2
	if p1.x<half_screen and p2.x>=half_screen:
		p1.x+=half_screen
	elif p2.x<half_screen and p1.x>=half_screen:
		p2.x+=half_screen
	
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(p1, p2, [self] )
	if result and result.collider.is_in_group("floor"):
		return 10000000
	else:
		return p1.distance_to(p2)
		
func die():
	dying=true
	$"../ScreechTimer".stop()
	$"../ChangeTimer".stop()
	collision_layer=0 
	collision_mask=0
	started=false
	
func fly_away():
	flying_out=true
	$"../ScreechTimer".stop()
	$"../ChangeTimer".stop()
	collision_layer=0 
	collision_mask=0
	started=false
	if global_position.x<(Global.screen_size.x/2):
		face(-1)
		velocity=Vector2(-300,0)
	else:
		face(1)
		velocity=Vector2(300,0)
		
func process_flying_out(delta):
	if global_position.x<-20 or global_position.x>(Global.screen_size.x+20):
		$"..".queue_free()
		return

	move_and_slide(velocity, Vector2(0, -1),false,4,0.785,true)

func _physics_process(delta):
	if flying_out:
		return process_flying_out(delta)

	if not started:
		return

	if dying:
		return
		
	if not onscreen and global_position.x>=0 and global_position.x<=Global.screen_size.x:
#		print("onscreen ",global_position.x," ",Global.screen_size.x)
		onscreen=true
		$"../ChangeTimer".wait_time=  time_to_change
		$"../ChangeTimer".start()
		
	face(abs(velocity.x))
	var previous_velocity=velocity
	move_and_slide(velocity, Vector2(0, -1),false,4,0.785,true)
	if $Mouth.get_overlapping_bodies().size()>0:
		print("something in my mouth...")
	for i in get_slide_count():
		var 	collision = get_slide_collision(i)
		if collision and collision.collider.is_in_group("player1"):
			print("collided with ", collision.collider.name)
		if collision != null and collision.collider.is_in_group("player") and collision.collider.state==collision.collider.STATE.PLAYING:
			print("hit player")
			# What's in my mouth
			if $"Mouth".overlaps_area(collision.collider.get_node("Lance/Area2D") ):
				print("Hit by lance!")
				$".."._on_Mouth_body_entered(collision.collider)
				return
			else:
				if Settings.god_mode and collision.collider.is_in_group("player1"):
					print("hit by god bird")
					$".."._on_Mouth_body_entered(collision.collider)
				else:
					collision.collider._on_Bird_hit(self)
			#$"../../PlayerBird".player1_hit()
		elif collision != null and collision.collider.is_in_group("floor"):
#			print("Collision: ",collision.normal)
#			print("Pre Velocity: ",velocity)
			$"../ChangeTimer".stop()
			$"../ChangeTimer".wait_time=randf()*1+0.25
			$"../ChangeTimer".start()
			if collision.normal.x!=0:
				velocity.x=collision.normal.x
			else:
				velocity.x=sign(velocity.x)

			if collision.normal.y!=0:
				velocity.y=randf()*sign(collision.normal.y)*.33*abs(velocity.x)
			else:
				velocity.y=velocity.y*velocity.x/previous_velocity.x
			velocity=velocity.normalized()*speed
#			print("Post Velocity: ",velocity)
	if not onscreen:
		return
	
	face(sign(velocity.x))
	global_position.x=wrapf(global_position.x, 0, Global.screen_size.x)
	global_position.y=clamp(global_position.y, 10, 530)


# Change where we're heading
func _on_ChangeTimer_timeout():
#	print('change direction')
	#face(not facing)
	#velocity.x*=-1
	
	var nearest_player=null
	var nearest_distance=10000000
	for player in players:
		if player.state!=player.STATE.PLAYING:
			continue
		var seen_distance=wrapped_distance(self, player)
		if seen_distance>see_distance:
			continue
		if seen_distance<nearest_distance:
			seen_distance=nearest_distance
			nearest_player=player
		
	# If no-one is near, do something random-ish	
	if nearest_player==null:
		#If we in the bottom half, look up
		if global_position.y>275 and not ($ForwardUp.is_colliding() and $ForwardUp.get_collider().is_in_group("floor") ):
			velocity=speed*Vector2(facing,-0.33).normalized()
		elif global_position.y<=275 and not ($ForwardDown.is_colliding() and $ForwardDown.get_collider().is_in_group("floor") ):
			velocity=speed*Vector2(facing,0.33).normalized()
		return
	
	# head toward nearest player without going more the 30 degrees up
	velocity=(nearest_player.global_position-global_position).normalized()
#	print("Direct Velocity: ",velocity, "   Speed: ", speed)
	velocity.y=clamp(velocity.y,-abs(velocity.x/3), abs(velocity.x/3) )
	velocity=velocity.normalized()
#	print("Pre Velocity: ",velocity, "   Speed: ", speed)
	velocity*=speed
#	print("Velocity: ",velocity, "   Speed: ", speed)
	face(sign(velocity.x))
	
	# Pick a random time to review velocity
	$"../ChangeTimer".wait_time=randf()*1+0.25
	$"../ChangeTimer".start()
