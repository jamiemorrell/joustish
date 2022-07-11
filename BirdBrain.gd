extends KinematicBody2D

signal hit
signal birdhit(bird, hit_by)
signal ready_player1
signal ready_player2
signal ready_npc

var Flame=preload("res://Flames.tscn")

var debug_no_brains=false

var run_speeds = [2500,7000,11000,13000,15000, 17000, 19000, 21000, 23000]
var playback_speeds = [ 0.85,2,3,3.5, 4.5, 5, 5.5, 6, 6.5]

var flap_speed = -150
var gravity = 320
var fly_step = 1

var velocity = Vector2(0,0)
var direction = 0
var is_alive = false
var will_live=false
var facing=1
var moving=1
var troll_coming=false
var see_distance={ "": 0 , "Bounder": 200, "Hunter": 350, "ShadowLord": 500}
var brain_speed={"": 0, "Bounder": 10, "Hunter": 8, "ShadowLord": 6 }

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


var Egg=preload("res://Egg.tscn")

func _ready():
	connect("birdhit",$"/root/World", "_on_bird_hit")
	state=STATE.ARRIVING
	layer=collision_layer
	mask=collision_mask
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

func remask():
	collision_layer=layer
	collision_mask=mask
	
func _process_grabbed(delta):
	velocity.x=0
	direction=0
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
				if is_in_group("player1"):
					if not Settings.god_mode:
						_on_Bird_hit(collision.collider)
				elif is_in_group("player2"):
					self.emit_signal("hit", collision.collider)
					
func _process_flying_out(delta):
	can_be_hit=false
	$Animations.play("flapping")
	$Animations.playback_speed=1
	$Rider.hide()
	unmask()
	if direction==0:
		if global_position.x<512:
			direction=-1
		else:
			direction=1
	if direction<0:
		face(-1)
		velocity=Vector2(-(run_speeds[-1]*delta),0)
	if direction>0:
		face(1)
		velocity=Vector2(run_speeds[-1]*delta,0)
	move_and_slide(velocity, Vector2(0, -1))
	var x=global_position.x
	if x<0 or x>1024:
		if remove:
			queue_free()
			return
		remask()
		if is_in_group("player1"):
			emit_signal("ready_player1")
		elif is_in_group("player2"):
			emit_signal("ready_player2")
		elif is_in_group("npc"):
			emit_signal("ready_npc")
		direction=0

func _process_flying_in(delta):
	$Rider.hide()
	$Animations.play("flapping")
	$Animations.playback_speed=1
	troll_coming=false
	unmask()
	if direction==0:
		direction=facing
	if direction<0:
		velocity=Vector2(-(run_speeds[-1]*delta),0)
	if direction>0:
		velocity=Vector2(run_speeds[-1]*delta,0)
	move_and_slide(velocity, Vector2(0, -1))
	if target and weakref(target).get_ref():
		if (facing>0 and global_position.x>=target.global_position.x) or (facing<0 and global_position.x<=target.global_position.x):
			print("found rider")
			state=STATE.PLAYING
			can_be_hit=true
			target.queue_free()
			$Rider.show()
			remask()
	else:
		var x=global_position.x
		if x<0 or x>1024:
			queue_free()

func _process_arriving(delta):
	unmask()

func _process_waiting(delta):
	return
	
func _physics_process(delta):
	#DebugState.text=str(int(global_position.x))+", "+str(int(global_position.y))
	#$DebugState.text=rider
	#$DebugState.text=str(state)
	$DebugState.text=str(direction)+"="+str($Animations.playback_speed)
	
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
		if $Animations.current_animation=="":
			queue_free()
		return
		
	if is_alive:
		birdbrain()
		
	if $Animations.current_animation=="stop":
		#if facing<0:
			#velocity.x-=run_speeds[abs(direction)-1]/400
		#else:
			#velocity.x+=run_speeds[abs(direction)-1]/400
		velocity.x=facing*50

	velocity.y+=delta*gravity
		
	if is_in_group("npc"):
		
		var wave_round : float =1+ ( 0.5* int((Global.wave-1)/90) )
		if rider=="Bounder":
			velocity.x=velocity.x*bounder_speed*wave_round
		elif rider=="Hunter":
			velocity.x=velocity.x*hunter_speed*wave_round
		elif rider=="ShadowLord":
			velocity.x=velocity.x*shadowlord_speed*wave_round
		else:
			velocity.x=velocity.x*npc_speed*wave_round

	var d
	if not is_on_floor():
		if is_cast_to_floor($CastFloor) :
			d=$CastFloor.global_transform.origin.distance_to($CastFloor.get_collision_point())
			d=clamp(10-clamp(d-31,0,10),4,10)
			$HitLegs.polygon[2].y=d
			$HitLegs.polygon[3].y=d
		elif sign(direction)==sign(facing) and is_cast_to_floor($CastFront) :
			d=$CastFront.global_transform.origin.distance_to($CastFront.get_collision_point())
			d=clamp(10-clamp(d-31,0,10),4,10)
			$HitLegs.polygon[2].y=d
			$HitLegs.polygon[3].y=d
		elif sign(direction)!=sign(facing) and is_cast_to_floor($CastBack) :
			d=$CastBack.global_transform.origin.distance_to($CastBack.get_collision_point())
			d=clamp(10-clamp(d-31,0,10),4,10)
			$HitLegs.polygon[2].y=d
			$HitLegs.polygon[3].y=d
		else:
			$HitLegs.polygon[2].y=4
			$HitLegs.polygon[3].y=4
			pass
			
	velocity=move_and_slide(velocity, Vector2(0, -1), false, 5, 0 , true)

	global_position.x=wrapf(global_position.x, 0, 1024)
	if global_position.y<10:
		velocity.y*=-0.8
	global_position.y=clamp(global_position.y, 10, 600)

	if is_on_floor() and get_slide_count() > 0:
		for ci in get_slide_count() :
			var collision = get_slide_collision(ci)
			if collision != null:
#				if is_in_group("player1"):
#					print("Collided with floor object: "+collision.collider.name+" "+collision.collider_shape.name)
				if (collision.collider.is_in_group("flames")):
					if is_in_group("player1"):
						if not Settings.god_mode:
							self.emit_signal("hit", collision.collider)
					elif is_in_group("player2"):
						self.emit_signal("hit", collision.collider)
					else:
						#print("floor")
						bird_hit_fire()
						return
				elif (collision.collider.is_in_group("ptero")) or (collision.collider.is_in_group("npc")):
					if is_in_group("	player1"):
						if not Settings.god_mode:
							_on_Bird_hit(collision.collider)
					elif is_in_group("player2"):
						_on_Bird_hit(collision.collider)					
	elif not is_on_floor() and get_slide_count() > 0:
		for ci in get_slide_count():
			var collision = get_slide_collision(ci)
			if collision != null:
				if (collision.collider.is_in_group("floor")):
					if is_in_group("player1"):
						print("Collided with "+collision.collider.name+" "+collision.collider_shape.name, collision.normal)
					if collision.normal.x!=0:
						direction=-direction
						velocity=-velocity
					#print("collision normal: "+str(collision.normal))
				elif (collision.collider.is_in_group("flames")):
					if is_in_group("player1"):
						if not Settings.god_mode:
							self.emit_signal("hit", collision.collider)
					elif is_in_group("player2"):
						self.emit_signal("hit", collision.collider)
					else:
						print("air")
						bird_hit_fire()
						return
				elif (collision.collider.is_in_group("bird")):
#					print("Hit a bird: "+collision.collider.name+" with my "+collision.collider_shape.name)
					var this_y=global_position.y
					var other_y=collision.collider.global_position.y
#					print("Me: "+str(this_y)+"   Him: "+str(other_y))

					# bounce if nearly the same
					if abs(other_y-this_y)<2:
						if (collision.normal.x<0 and direction>0) or (collision.normal.x>0 and direction<0):
							#collision.collider.direction=-collision.collider.direction
							direction=-direction
							$SoundThunk.play()
					else:
						if Settings.god_mode:
							if is_in_group("player"):
								collision.collider.unmask()
								collision.collider.emit_signal("hit", self)
							elif collision.collider.is_in_group("player"):
								unmask()
								self.emit_signal("hit", collision.collider)
						else:
							if this_y<other_y:
								collision.collider.unmask()
								collision.collider.emit_signal("hit", self)
							elif this_y>other_y:
								unmask()
								self.emit_signal("hit", collision.collider)

	var wave_round : float =1+ ( 0.5* int((Global.wave-1)/180) )
		
	if (direction<0):
		velocity.x = -delta * ( run_speeds[abs(direction)-1]) *wave_round
	if (direction>0):
		velocity.x = delta * ( run_speeds[abs(direction)-1] ) * wave_round

	if direction==0:
		velocity.x=0

	if (not is_on_floor() ) and $Animations.assigned_animation!="flap":
		$Animations.playback_speed=1
		$Animations.play("flap")
		
	if is_on_floor() and $Animations.assigned_animation!="stop":
		if $Animations.assigned_animation=="flap":
			$SkidDust.emitting=true
			$SoundThunk.play()
			
		if direction==0:
			$Animations.play("default")
		else:
			if $Animations.assigned_animation=="flap":
				direction=int(direction)
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
			$Animations.playback_speed=playback_speeds[abs(direction)-1]*rider_speed
			
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
		if abs(direction)>1:
			$Animations.play("stop")
			var sp=7.0/abs(direction)
			$Animations.playback_speed=sp
			$Animations.queue("default")
		else:
			$Animations.play("default")
		direction=0

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
	if is_on_floor():
		if direction>0:
			stop()
		else:
			go_direction(direction-1)
	else:
		if facing==1:
			scale.x*=-1
			facing*=-1
		go_direction(direction-fly_step)

func flap():
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
		
func right():
	stop_waiting()
	if is_on_floor():
		if direction<0:
			stop()
		else:
			go_direction(direction+1)
	else:
		if facing<0:
			facing*=-1
			scale.x*=-1
		go_direction(direction+fly_step)
		
func player_arrive(pod, face_to):
	print("player_arrive to "+str(pod))
	face(face_to)
	hide()
	$HitLegs.polygon[2].y=10
	$HitLegs.polygon[3].y=10
	arrive(pod)
	return self

func npc_arrive(owner, pod, face_to, rider):
	add_to_group("npc")
	$SoundFlap.volume_db=-80
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
	print("npc bird arrive to "+str(pos))
	face(face_to)
	$HitLegs.polygon[2].y=10
	$HitLegs.polygon[3].y=10
	will_live=true
	hide()
	owner.add_child(self)
	global_position=pos
	set_rider(rider)
	return self
	
# slide up from a position
func arrive(pod):
	var pos=get_node("/root/World/Pods/Pod"+str(pod)).global_position
	velocity=Vector2(0,0)

	if is_in_group("enemy"):
		get_node("/root/World/Pods/Pod"+str(pod)+"/AnimationPlayer").play("flash")
		$Animations.play("birth")
	else:
		print("playerbirth")
		$Animations.stop()
		get_node("/root/World/Pods/Pod"+str(pod)+"/AnimationPlayer").play("flashplayer")
		$Animations.play("playerbirth")

	global_position=pos-Vector2(0,abs($Base.position.y*scale.y)-2)
	return

func go_direction(dir):
	direction=clamp(dir,-run_speeds.size(),run_speeds.size() )
	if abs(direction)>0:
		$SoundSkid.stop()
		if $Animations.assigned_animation=="stop" and is_on_floor():
			$Animations.playback_speed=1.0
			$Animations.play("walk")

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
	if global_position.y>player_bird.global_position.y:
		flap()

func is_looking_at(player_bird):
	return sign(facing)==sign(player_bird.global_position.x-global_position.x )

func birdbrain():
	if debug_no_brains:
		return
	var player1=$"/root/World/PlayerBird/Bird"
	var player2=$"/root/World/PlayerBird2/Bird"
	var s=OS.get_screen_size()
	var dp1=10000000
	var dp2=10000000
	if $"/root/World/".p1_lives>0 and player1.state==STATE.PLAYING:
		dp1=wrapped_distance(self, player1)

	if Global.players>1 and $"/root/World/".p2_lives>0 and player2.state==STATE.PLAYING:
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
			
	if (direction==0):
		if (randi() % 2 )==0:
			left()
		else:
			right()
		return
	if (facing>0):
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
		if Global.wave>=3 and $CastFloor.is_colliding() and $CastFloor.get_collider().is_in_group("flames"):
			if randi()%5==0:
				flap()
		else:
			# Make odds of flapping increase the lower the bird is
			var c=int(s.y-global_position.y)/30+10
			if (randi()%c)==0 :
				flap()

func waiting_for_player_input():
	collision_mask=1
	print("start waiting...")
	state=STATE.WAITING
	
func _on_Animations_animation_finished(anim_name):

	if anim_name=="birth" or anim_name=="playerbirth":
		state=STATE.PLAYING
		remask()		

		if will_live and not is_alive:
			is_alive=true

func bird_hit_fire():
	print("bird hit fire "+name+" can be hit "+str(can_be_hit))
	if not can_be_hit:
		return
	can_be_hit=false
	is_alive=false
	state=STATE.DYING
	$SoundKill.play()
	var p=$"/root/World"
	var f=Flame.instance()
	f.global_position=global_position
	f.global_position.y=$"/root/World/Flames".global_position.y
	p.add_child(f)
	f.get_node("Animations").play("flameegg")
	$Animations.playback_speed=1
	$Animations.play("burnup")
	#queue_free()

func _on_Bird_hit(other_bird):
	if not can_be_hit:
		return
	can_be_hit=false
	print(name+" hit")
	emit_signal("birdhit", self, other_bird)
	if is_in_group("npc") :
		var p=$".."
		print("dropping egg in "+p.name)
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

