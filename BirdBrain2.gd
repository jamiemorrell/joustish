extends KinematicBody2D

signal hit
signal birdhit(bird, hit_by)
signal ready_player1
signal ready_player2
signal ready_npc

var Flame=preload("res://Flames.tscn")

var wave_round : float
var debug_no_brains=false

var run_speed_step_default = 40
var run_speed_max_default = 400
var run_speed_step = 40
var run_speed_max = 400
var skid_speed
var stuck_count:int =0 
var min_kick : int = 300

var already_colliding=[]
var flap_speed = -150
var gravity = 320
var fly_step = 1
var noflap : bool = false

var velocity = Vector2(0,0)
var previous_velocity : Vector2
var previous_position : Vector2
var is_alive = false
var will_live=false
var facing=1
var troll_coming=false
var see_distance={ "": 0 , "Bounder": 400, "Hunter": 550, "ShadowLord": 650}
var brain_speed={"": 0, "Bounder": 8, "Hunter": 6, "ShadowLord": 5 }

var rider=""
enum STATE {FLYING_IN, FLYING_OUT, PLAYING, ARRIVING, DYING, GRABBED, WAITING}
var state
var layer
var mask
var npc_speed=0.25
var bounder_speed=0.25
var hunter_speed=0.5
var shadowlord_speed=0.8
var can_be_hit=true
var target
var remove
var last_seen : Vector2

var Egg=preload("res://Egg.tscn")
var Hat=preload("res://Hat.tscn")

func reparent(what : Node, where : Node, pos : Vector2):
	var h=what.duplicate()
	
	add_child(h)
	#yield(get_tree(), "idle_frame")
	what.queue_free()
	#what.position=pos

func _ready():

		
	if not OS.has_feature("editor"):
		$DebugState.visible=false
		
	connect("birdhit",$"/root/World", "_on_bird_hit")
	state=STATE.ARRIVING
	layer=collision_layer
	mask=collision_mask
	#wave_round =1+ ( 0.5* int((Global.wave-1)/180) )
	hide()

func set_rider(r):
	
	rider=r
	var riders=$Rider.get_children()
	$Rider.hide()
	for r in range(riders.size() ):
		riders[r].hide()
	if r!="":
		$Rider.show()
		can_be_hit=true
		get_node("Rider/"+r).show()

func unmask():
	collision_layer=0
	collision_mask=0
	can_be_hit=false

func remask():
	can_be_hit=true
	collision_layer=layer
	collision_mask=mask
	
func _process_grabbed(delta):
	velocity.x=0
	velocity.y+=delta*gravity*(2.5+2.0*smoothstep(4,90,Global.wave))
	move_and_slide(velocity, Vector2(0, -1))
	for i in get_slide_count():
		var 	collision = get_slide_collision(i)
		if collision != null:
			if (collision.collider.is_in_group("flames")):
				if is_in_group("player1"):
					if not Settings.god_mode:
						get_tree().call_group("troll_hand", "free_bird_troll", self )
						self.emit_signal("hit", collision.collider)
				elif is_in_group("player2"):
					get_tree().call_group("troll_hand", "free_bird_troll", self )
					self.emit_signal("hit", collision.collider)
				else:
					get_tree().call_group("troll_hand", "free_bird_troll", self )
					bird_hit_fire()
	
			if (collision.collider.is_in_group("ptero")):
				if is_in_group("player1") and not Settings.god_mode:
					_on_Bird_hit(collision.collider)
				elif is_in_group("player2"):
					_on_Bird_hit(collision.collider)
					
func _process_flying_out(delta):
	can_be_hit=false
	$Animations.play("flapping")
	$Animations.playback_speed=1
	$Rider.hide()
	unmask()

	var x=global_position.x
	if x<-40 or x>1064:
		velocity=Vector2(0,0)
		if not is_in_group("player") and remove:
#			print("remove me!")
			queue_free()
			return
		remask()
		face(-facing)
		if is_in_group("player1"):
			emit_signal("ready_player1")
		elif is_in_group("player2"):
			emit_signal("ready_player2")
		elif is_in_group("npc"):
			emit_signal("ready_npc")
		return
	
	yield(get_tree(), "idle_frame")
	if velocity.x==0:
		if global_position.x<(Global.screen_size.x/2):
			face(-1)
		else:
			face(1)
		velocity=Vector2(sign(facing)*run_speed_step_default*10, 0)
	if velocity.x<0:
		face(-1)
		velocity=Vector2(-run_speed_step_default*10,0)
	if velocity.x>0:
		face(1)
		velocity=Vector2(run_speed_step_default*10,0)

	global_position=global_position+velocity*delta

	
func _process_flying_in(delta):
	$Rider.hide()
	$Animations.play("flapping")
	$Animations.playback_speed=1
	troll_coming=false
	unmask()
	if velocity.x==0:
		if global_position.x<10:
			face(1)
		elif global_position.x>1014:
			face(-1)
	if facing<0:
		velocity=Vector2(-run_speed_step_default*10,0)
	if facing>0:
		velocity=Vector2(run_speed_step_default*10,0)
	move_and_slide(velocity, Vector2(0, -1))

	if target and weakref(target).get_ref():
		if (facing>0 and global_position.x>=target.global_position.x) or (facing<0 and global_position.x<=target.global_position.x):
#			print("found rider")
			state=STATE.PLAYING
			can_be_hit=true
			target.queue_free()
			$Rider.show()
			velocity=Vector2(0,0)
			remask()
	else:
		var x=global_position.x
		if x<0 or x>1024:
			queue_free()

func _process_arriving(delta):
	unmask()

func _process_waiting(delta):
	return

func bounce_x(amount : float=0.8, normal: Vector2=Vector2(0,0) ):
	$BounceTimer.start()
	global_position=previous_position
	velocity=amount*previous_velocity.bounce(normal)
	if abs(velocity.x)<100:
		velocity.x=-sign(normal.x)*100

func combine_velocities(object1, object2):
	return object1.previous_velocity-object2.previous_velocity

func bounce(amount: float=0.8, normal: Vector2=Vector2(0,0), last_velocity : Vector2 = previous_velocity):
	$BounceTimer.start()

	global_position=previous_position
	yield(get_tree(), "idle_frame")
	velocity=amount*last_velocity.length()*normal.normalized()
	velocity.y*=-1
	velocity.x*=-1
	#if sign(velocity.y)==sign(previous_velocity.y):
	#	velocity.y=-velocity.y
	#if abs(velocity.y)<100:
	#		velocity.y=sign(velocity.y)*100
	print(name, " bounce ", last_velocity," ", normal, " ", velocity)

			
func _physics_process(delta):
	wave_round =1.0+ float( 0.5* float((Global.wave-1.0)/90.0) )

	run_speed_step = run_speed_step_default * wave_round
	run_speed_max = run_speed_max_default  * clamp(wave_round,1.0,1.5)

	if rider=="Bounder":
		run_speed_max*=bounder_speed
		run_speed_step*=bounder_speed
	elif rider=="Hunter":
		run_speed_max*=hunter_speed
		run_speed_step*=hunter_speed
	elif rider=="ShadowLord":
		run_speed_max*=shadowlord_speed
		run_speed_step*=shadowlord_speed

	#if is_in_group("player1"):
#		print(wave_round, " ", name, " ", run_speed_step, " ", run_speed_max)
#	if is_in_group("player1"):
#		print("wave round ",wave_round, Global.wave)	
	#DebugState.text=str(int(global_position.x))+", "+str(int(global_position.y))
	#$DebugState.text=rider
	$DebugState.text=str(state)
	#$DebugState.text=str(direction)+"="+str($Animations.playback_speed)
	#$DebugState.text=str(int(velocity.x) )
	
	if state==STATE.FLYING_OUT :
		return _process_flying_out(delta)

	if state==STATE.FLYING_IN :
		return _process_flying_in(delta)
	
	if state==STATE.ARRIVING :
		return _process_arriving(delta)

	if state==STATE.GRABBED :
		return _process_grabbed(delta)

	if state==STATE.WAITING :
		return _process_waiting(delta)
		
	if state==STATE.DYING:
		#print("Animation: "+$Animations.current_animation)
		if $Animations.current_animation=="" and not is_in_group("player"):
			queue_free()
		return
		
	if is_alive:
		birdbrain()
		
	if $Animations.current_animation=="stop":

		velocity.x=skid_speed
		skid_speed*=0.9
		if abs(velocity.x)<1:
			velocity.x=0
			$Animations.play("default")

	velocity.y+=delta*gravity
		

	var d
	if not is_on_floor():
		if is_cast_to_floor($CastFloor) :
			d=$CastFloor.global_transform.origin.distance_to($CastFloor.get_collision_point())
			d=clamp(10-clamp(d-31,0,10),4,10)
			$HitLegs.polygon[2].y=d
			$HitLegs.polygon[3].y=d
		elif sign(velocity.x)==sign(facing) and is_cast_to_floor($CastFront) :
			d=$CastFront.global_transform.origin.distance_to($CastFront.get_collision_point())
			d=clamp(10-clamp(d-31,0,10),4,10)
			$HitLegs.polygon[2].y=d
			$HitLegs.polygon[3].y=d
		elif sign(velocity.x)!=sign(facing) and is_cast_to_floor($CastBack) :
			d=$CastBack.global_transform.origin.distance_to($CastBack.get_collision_point())
			d=clamp(10-clamp(d-31,0,10),4,10)
			$HitLegs.polygon[2].y=d
			$HitLegs.polygon[3].y=d
		else:
			$HitLegs.polygon[2].y=4
			$HitLegs.polygon[3].y=4
			pass
			
	previous_velocity=velocity
	previous_position=global_position
	velocity=move_and_slide(velocity, Vector2(0, -1), false, 5, 0 , true)

	global_position.x=wrapf(global_position.x, 0, 1024)
	if global_position.y<10:
		velocity.y*=-0.9
	global_position.y=clamp(global_position.y, 10, 600)

	var is_player1=is_in_group("player1")
	var is_player2=is_in_group("player2")
		
	if get_slide_count() > 0:
		var colliding_with_birds=[]
		for ci in get_slide_count():
			var collision = get_slide_collision(ci)
			if collision != null:
				var other_is_player1=collision.collider.is_in_group("player1")
				var other_is_player2=collision.collider.is_in_group("player2")
				if (collision.collider.is_in_group("flames")):
					if is_player1:
						if not Settings.god_mode:
							_on_Bird_hit( collision.collider)
							return
					elif is_player2:
						_on_Bird_hit( collision.collider)
						return
					else:
					#print("floor")
						bird_hit_fire()
						return
				elif collision.collider.is_in_group("ptero"):
					if is_player1 and not Settings.god_mode:
						_on_Bird_hit(collision.collider)
						return
					elif is_player2:
						_on_Bird_hit(collision.collider)
						return
				elif collision.collider.is_in_group("floor") and not is_on_floor():
					$BounceTimer.start()
					global_position=previous_position
					velocity = 0.4*previous_velocity.bounce(collision.normal)
					if not is_in_group("player"):
						face(sign(velocity.x))
				elif can_be_hit  and collision.collider.is_in_group("bird") and collision.collider.can_be_hit and not already_colliding.has(collision.collider_id) and not collision.collider.already_colliding.has(get_instance_id()):
#					print("Hit a bird: "+collision.collider.name+" with my "+collision.collider_shape.name)
					var this_y=global_position.y
					var other_y=collision.collider.global_position.y

					colliding_with_birds.append(collision.collider_id)
					already_colliding.append(collision.collider_id)
					collision.collider.already_colliding.append(get_instance_id() )
					print("Mine ", already_colliding)
					print("His ", collision.collider.already_colliding)
							

					if abs(other_y-this_y)<=3:

						global_position=previous_position
						velocity=previous_velocity
						var b=(collision.collider.global_position-global_position).normalized()
						var c=combine_velocities(self, collision.collider)
						print("length", c.length() )
						if c.length()<min_kick:
							c=c.normalized()*min_kick
							print("increased kick")
						bounce(0.7, b, c/2)
						collision.collider.bounce(0.7, -b, -c/2)
						$SoundThunk.play()
					else:
						if is_player1 and Settings.god_mode:
							# If we are P1 and in god mode, bodge the height so we win
							this_y=other_y-10
						elif other_is_player1 and Settings.god_mode:
							# If we hit P1 and in god mode, bodge the height so we lose
							this_y=other_y+10
							
						if this_y<other_y :
							if is_player1:
								print("p1 attacked a bird")
							elif other_is_player1:
								print("bird attacked p1")


							global_position=previous_position
							yield(get_tree(), "idle_frame")
							velocity=previous_velocity
							var b=(collision.collider.previous_position-previous_position).normalized()
							var c=combine_velocities(self, collision.collider)
							print("length", c.length() )
							if c.length()<min_kick:
								c=c.normalized()*min_kick
								print("increased kick")
							var this_vel=c/2
							var that_vel=-c/2
							var this_norm=b
							var that_norm=-b
							if collision.collider.is_on_floor():
								this_vel.y=c.y
								that_vel.y=0
								this_norm.y*=2
								that_norm.y=0
							if is_on_floor():
								that_vel.y=c.y
								this_vel.y=0
								that_norm.y*=2
								this_norm.y=0
							bounce(0.8, this_norm, this_vel)
							if collision.collider.has_hat():
								collision.collider.bounce(0.8,that_norm, that_vel)
								collision.collider.drop_hat()
							else:
								collision.collider._on_Bird_hit( self)
						elif this_y>other_y :
							if is_player1:
								print("p1 attacked by bird")
							if other_is_player1:
								print("bird attacked by p1")
							global_position=previous_position
							yield(get_tree(), "idle_frame")
							velocity=previous_velocity
							var b=(collision.collider.previous_position-previous_position).normalized()
							var c=combine_velocities(self, collision.collider)
							print("length", c.length() )
							if c.length()<min_kick:
								c=c.normalized()*min_kick
								print("increased kick")
							var this_vel=c/2
							var that_vel=-c/2
							var this_norm=b
							var that_norm=-b
							if collision.collider.is_on_floor():
								this_vel.y=c.y
								that_vel.y=0
								this_norm.y*=2
								that_norm.y=0
							if is_on_floor():
								that_vel.y=c.y
								this_vel.y=0
								that_norm.y*=2
								this_norm.y=0
							collision.collider.bounce(0.8, that_norm, that_vel)
							if has_hat():
								bounce(0.8, this_norm, this_vel)
								drop_hat()
							else:
								_on_Bird_hit(collision.collider)
		var tmp=[]
		for i in already_colliding.size():
			if colliding_with_birds.has(already_colliding[i]):
				tmp.append(already_colliding[i])
			else:
				print("no longer colliding with ", already_colliding[i])
		if already_colliding.size()!=tmp.size():
			print("was colliding ", already_colliding)
			print("is colliding ", tmp)
		already_colliding=tmp

	else:
		already_colliding=[]
		
	if (not is_on_floor() ) and $Animations.assigned_animation!="flap":
		$Animations.playback_speed=1
		$Animations.play("flap")
		
	if is_on_floor() and $Animations.assigned_animation!="stop":
		if $Animations.assigned_animation=="flap":
			$SkidDust.emitting=true
			$SoundThunk.play()
			
		if velocity.x==0:
			$Animations.play("default")
		else:
#			if $Animations.assigned_animation=="flap":
#				direction=int(direction)
			$Animations.play("walk")
			var rider_speed=1.0
			if rider=="Bounder":
				rider_speed=bounder_speed
			elif rider=="Hunter":
				rider_speed=hunter_speed
			elif rider=="ShadowLord":
				rider_speed=shadowlord_speed
			elif is_in_group("enemy"):
				rider_speed=npc_speed
			$Animations.playback_speed=0.5*(abs(velocity.x)/(1.0*run_speed_step))*rider_speed
			
	# Only change direction if we're moving on the floor
	if is_on_floor():
#	if velocity.x!=0:
		if (velocity.x>0 and facing<0) or (velocity.x<0 and facing>0) :
			scale.x*=-1
			facing*=-1

func is_cast_to_floor(ray):
	return ray.is_colliding() and ray.get_collider().is_in_group("floor")
	
func stop():
	if is_on_floor():
		if abs(velocity.x)>run_speed_step:
			$Animations.play("stop")
			var sp=10.0/abs(velocity.x/(run_speed_step))
			$Animations.playback_speed=sp
			skid_speed=velocity.x/10
			$Animations.queue("default")
		else:
			$Animations.play("default")
			skid_speed=0
			velocity.x=0
		#velocity.x=0

func face(f):
	if f!=facing:
		scale.x*=-1
		facing=f

func stop_waiting():
	if state==STATE.WAITING:
		remask()
		$Bird.modulate.a=1
		$Rider.modulate.a=1
		state=STATE.PLAYING
	
func left():
	stop_waiting()
	if $BounceTimer.time_left>0:
		return
	if is_on_floor():
		if $Animations.current_animation=="stop":
			return
		if velocity.x>0:
			stop()
		else:
			velocity.x-=run_speed_step
			if velocity.x<-run_speed_max:
				velocity.x=-run_speed_max
	else:
		if facing==1:
			scale.x*=-1
			facing*=-1
		velocity.x-=run_speed_step
		if velocity.x<-run_speed_max:
			velocity.x=-run_speed_max

func right():
	stop_waiting()
	if $BounceTimer.time_left>0:
		return
	if is_on_floor():
		if $Animations.current_animation=="stop":
			return	
		if velocity.x<-0:
			
			stop()
		else:
			velocity.x+=run_speed_step
			if velocity.x>run_speed_max:
				velocity.x=run_speed_max
	else:
		if facing<0:
			facing*=-1
			scale.x*=-1
		velocity.x+=run_speed_step
		if velocity.x>run_speed_max:
			velocity.x=run_speed_max

func flap():
	if noflap:
		return
	stop_waiting()
	if velocity.y<0:
		velocity.y=0
	velocity.y = flap_speed
	$Animations.playback_speed=1
	$Animations.play("flap")
	var p=0.9+float(randi()%20)/50
	$SoundFlap.pitch_scale=p
	$SoundFlap.play()
	$SkidDust.emitting=false
	$SoundSkid.stop()
		

		
func player_arrive(pod, face_to):
	face(face_to)
	hide()
	$HitLegs.polygon[2].y=10
	$HitLegs.polygon[3].y=10
	arrive(pod)
	return self

func npc_arrive(owner, pod, face_to, rider):
	add_to_group("npc")
	$SoundFlap.volume_db=-80
	#$SoundThunk.volume_db=-80
	$SoundSkid.volume_db=-80
	$SoundStepLo.volume_db=-80
	$SoundStepHi.volume_db=-80
	
	#print("npc bird arrive to "+str(pod))
	face(face_to)
	$HitLegs.polygon[2].y=10
	$HitLegs.polygon[3].y=10
	will_live=true
	hide()
	owner.add_child(self)
	arrive(pod)
	set_rider(rider)
	return self

func npc_arrive_pos(owner, pos, face_to, rider):
	add_to_group("npc")
	face(face_to)
	$HitLegs.polygon[2].y=10
	$HitLegs.polygon[3].y=10
	will_live=true
	hide()
	owner.add_child(self)
	global_position=pos
	set_rider(rider)
	return self

func put_on_hat(hat):
	print(name, " told to put on hat!")
	if $Hat!=null:
		print("Already wearing a hat, thank you!")
		return
	hat.queue_free()
	var h=Hat.instance()
	add_child(h)
	h.collision_mask=0
	h.position=$HatPosition.position
	h.scale=$HatPosition.scale

func has_hat():
	return $Hat!=null
	
func drop_hat():

	print(name, " told to drop hat!")
	if not $Hat:
		print("but I have no hat any more!")
		return
	$Hat.free()
	$SoundThunk.play()
	#hat.queue_free()
	var h=Hat.instance()
	$"/root/World".add_child(h)
	
	h.collision_mask=1
	yield(get_tree(), "idle_frame")
	h.global_position=$HatPosition.global_position
	h.rotation_degrees=45
	h.velocity=Vector2(-50,-50)
	h.scale=Vector2(1,1)
	
	
# slide up from a position
func arrive(pod):
	var pos=get_node("/root/World/Pods/Pod"+str(pod)).global_position
	velocity=Vector2(0,0)

	if is_in_group("enemy"):
		get_node("/root/World/Pods/Pod"+str(pod)+"/AnimationPlayer").play("flash")
		$Animations.play("birth")
	else:
		$Animations.stop()
		get_node("/root/World/Pods/Pod"+str(pod)+"/AnimationPlayer").play("flashplayer")
		$Animations.play("playerbirth")

	global_position=pos-Vector2(0,abs($Base.position.y*scale.y)-2)
	return


func hunter_brain():
	pass

func shadowlord_brain():
	pass


func wrapped_distance(o1,o2):
	var s=OS.get_screen_size()
	var p1=o1.global_position
	var p2=o2.global_position
	var half_screen=s.x/2
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

func move_towards(player_bird):
	var screen_size=OS.get_screen_size()
	if global_position.x<player_bird.global_position.x:
		right()
	elif global_position.x>player_bird.global_position.x:
		left()
	if not $CastAbove.is_colliding() and global_position.y>player_bird.global_position.y:
		flap()

func is_looking_at(player_bird):
	return sign(facing)==sign(player_bird.global_position.x-global_position.x )

func birdbrain():
	if debug_no_brains:
		return
		
	if state==STATE.GRABBED:
		if randi()%2==0:
			flap()
			return

	if troll_coming:
		if randi()%(brain_speed[rider]/4)==0:
			flap()
			return


	if state==STATE.PLAYING and int(global_position.x)==int(previous_position.x) and int(global_position.y)==int(previous_position.y):
#	if abs(velocity.x)<3.0 and abs(velocity.y)<3.0:
		if stuck_count>0:
			print(name, " ", velocity,' ',stuck_count, ' ', Vector2(int(global_position.x), int(global_position.y)))
		stuck_count+=1
		if stuck_count>10:
			noflap=true
		elif stuck_count>5:
			$BounceTimer.stop()
			if $CastFront.is_colliding():
				if facing<0:
					right()
					right()
				else:
					left()
					left()
			elif facing<0:
				left()
				left()
			else:
				right()
				right()
			flap()
	else:
		stuck_count=0
		noflap=false
		
	var player1=$"/root/World/PlayerBird/Bird"
	var player2=$"/root/World/PlayerBird2/Bird"
	var s=OS.get_screen_size()
	var dp1=10000000
	var dp2=10000000
	if $"/root/World/".p1_lives>0 and (player1.state==STATE.PLAYING or player1.state==STATE.GRABBED):
		dp1=wrapped_distance(self, player1)

	if Global.players>1 and $"/root/World/".p2_lives>0 and (player2.state==STATE.PLAYING or player2.state==STATE.GRABBED):
		dp2=wrapped_distance(self, player2)
		
	# if both players in view, pick the one we are facing, or nearest
	if dp1<see_distance[rider] and dp2<see_distance[rider]:
		if is_looking_at(player1) and not is_looking_at(player2):
			dp2=10000000
		elif is_looking_at(player2) and not is_looking_at(player1):
			dp1=10000000	
		elif dp1<dp2:
			dp2=10000000
		else:
			dp1=10000000

	if dp1<see_distance[rider] and randi()%brain_speed[rider]==0:
		move_towards(player1)
	if dp2<see_distance[rider] and randi()%brain_speed[rider]==0:
		move_towards(player2)
			
	if (abs(velocity.x)<run_speed_step):
		if (randi() % 10 )==0:
			if velocity.x<0:
				right()
			else:
				left()
		else:
			if velocity.x<0:
				left()
			else:
				right()
		return
	if (velocity.x>0):
		if (randi() % 100 )==0:
			left()
		else:
			if (randi() % 20 )==0:
				right()
	else:
		if (randi() % 100 )==0:
			right()
		else:
			if (randi() % 20 )==0:
				left()
	if is_on_floor():
		if (randi()%20)==0:
			flap()
	else:
		if velocity.y>300 and global_position.y>300:
			#print("y ", velocity.y)
			if randi()%(brain_speed[rider]/3)==0:
				flap()
				return
		if Global.wave>=3 and $CastFloor.is_colliding() and $CastFloor.get_collider().is_in_group("flames"):
			if (randi()%2)==0:
				flap()
		else:
			
			# Make odds of flapping increase the lower the bird is
			var c=int(s.y-global_position.y)/30+10
			if not $CastAbove.is_colliding() and (randi()%c)==0 :
				flap()

func waiting_for_player_input():
	collision_mask=1
	state=STATE.WAITING
	
func _on_Animations_animation_finished(anim_name):
	if anim_name=="stop":
		velocity.x=0
		skid_speed=0
	elif anim_name=="birth" or anim_name=="playerbirth":
		state=STATE.PLAYING
		remask()		

		if will_live and not is_alive:
			is_alive=true

func bird_hit_fire():
#	print("bird hit fire "+name+" can be hit "+str(can_be_hit))
	if not can_be_hit:
		return
	can_be_hit=false
	is_alive=false
	state=STATE.DYING
	$SoundKill.play()
	var p=$"/root/World"
	var f=Flame.instance()
	p.add_child(f)
	f.global_position=global_position
	f.global_position.y=$"/root/World/Flames".global_position.y
	f.get_node("Animations").play("flameegg")
	$Animations.playback_speed=1
	$Animations.play("burnup")
	#queue_free()
func burned():
	if not is_in_group("player"):
		queue_free()
		
func _on_Bird_hit(other_bird):

	unmask()
	if is_in_group("player1"):
		print("p1 hit by ",other_bird)
	if is_in_group("enemy"):
		print("enemy hit by ", other_bird)
	emit_signal("birdhit", self, other_bird)
	if is_in_group("npc") :
		var p=$".."
#		print("dropping egg in "+p.name)
		var e=Egg.instance()
		e.position=position
		e.collision_mask=1 
		e.set_axis_velocity(velocity)
		e.angular_velocity=float(randi()%10/10)
		p.add_child(e)
		e.start_spin()
		e.connect("egg_hit", p, "egg_hit")
		if rider=="Hunter":
			rider="ShadowLord"
		if rider=="Bounder":
			rider="Hunter"
		e.rider=rider
		e.bird=self
	$SoundKill.play()
	set_rider("")
	state=STATE.FLYING_OUT

func stop_skidding():
	skid_speed=0
	velocity.x=0
	
