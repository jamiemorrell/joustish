extends Node2D

signal bird_arrived

export var test_wave:bool=true
var test_highscores=false
var BirdStork=preload("res://BirdStork.tscn")
var BirdBuzzard=preload("res://BirdBuzzard.tscn")
var BirdOstrich=preload("res://BirdOstrich.tscn")
var Explosion=preload("res://Explosion.tscn")
var Points=preload("res://Points.tscn")
var Egg=preload("res://Egg.tscn")
var Hat=preload("res://Hat.tscn")
var Troll=preload("res://Troll.tscn")
var Ptero=preload("res://Ptero.tscn")

var wave_rng = RandomNumberGenerator.new()
var ptero_rng = RandomNumberGenerator.new()
var hat_rng = RandomNumberGenerator.new()

var bounders=[3,4,6,3,12,3,2,0,0,12,3,2]
var hunters=[0,0,0,3,0,3,4,6,6,0,5,6,7,8,12,5,5,5,4,12,3,2,2,2,12,3,3,2,3,12,4,2,2,2,12,2,0,0,0,12,3,0,0,0,12,3,0,0,0,12,3,0,0,0,12,3]
var shadowlords=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,0,3,4,4,4,0,5,5,4,5,0,4,6,4,6,0,6,8,6,8,0,7,10,7,10,0,7,10,7,10,0,7,10,7,10,0,7,10,7,10,12,10,10,7,10,12,10,10,7,10,12,10,10,7,10,12,10,10,7,10,12,10,10,7,10,12,10,10,7,10,12]

var wave=1

var start_lives=5
var start_score=0
var start_wave=1
var floor_wave=3
var troll_wave=4
var p1_lives=0
var bonus_lives1=0
var p2_lives=0
var bonus_lives2=0
var wave_started=false
var score1
var score2
var survived=true
var gladiator=0
var p1team=true
var p2team=true
var egg_score_idx1=0
var egg_score_idx2=0
var egg_scores=[250,500,750,1000]
var enemies_waiting=[]
var pteros_waiting=[]
var timeout_pteros_waiting=[]
var highscoreref

# Called when the node enters the scene tree for the first time.
func _ready():
	$PauseScreen.visible=false
	highscoreref = Global.db.get_reference_lite("joustish/highscores")
	if Global.players==1:
		game_start()
	elif Global.players==2:
		game_start_2()
	$EnterInitials1.hide()
	$EnterInitials2.hide()


func game_over():
	$PteroTimer._stop()
	Global.typing=true
	Global.last_score1=score1
	if Global.players==2:
		Global.last_score2=score2

	$HUD/Animations.play("game_over_fade")
	
	$PlayerBird.set_game_over()
	if Global.players==2:
		$PlayerBird2.set_game_over()
			
	if test_highscores or (not Global.cheated and score1>0 and (Global.table.size()<10 or (Global.table.size()>0 and Global.table[-1].score<score1) ) ) or (not Global.cheated and score1>0 and (Global.today_table.size()<10 or (Global.today_table.size()>0 and Global.today_table[-1].score<score1) ) ):
		var initials1="??1"
		$EnterInitials1/Initials.text=""
		$EnterInitials1.show()
		#$EnterInitials1/Initials.text="???"
		$EnterInitials1/Initials.grab_focus()

		initials1=yield($EnterInitials1/Initials, "text_entered")
		initials1=initials1.to_upper()
		if initials1=="":
			initials1="???"
		print("initials", initials1)
		Global.add_high_score({"score":score1, "wave":wave, "name": initials1})
		$EnterInitials1.hide()

	if (test_highscores and Global.players==2) or (not Global.cheated and Global.players==2 and score2>0 and (Global.table.size()<10 or (Global.table.size()>0 and Global.table[-1].score<score2) ) ) or (not Global.cheated and Global.players==2 and score2>0 and (Global.today_table.size()<10 or (Global.today_table.size()>0 and Global.today_table[-1].score<score2) ) ):
		var initials2="??2"
		$EnterInitials2/Initials.text
		$EnterInitials2.show()
		#$EnterInitials1/Initials.text="???"
		$EnterInitials2/Initials.grab_focus()

		initials2=yield($EnterInitials2/Initials, "text_entered")
		initials2=initials2.to_upper()
		if initials2=="":
			initials2="???"
		print("initials", initials2)
		Global.add_high_score({"score":score2, "wave":wave, "name": initials2})
		$EnterInitials2.hide()
		
	Global.get_high_scores()
	
	$GameOverTimer.start()
	yield( $GameOverTimer, "timeout")
	Global.typing=false
	get_tree().change_scene("res://Intro.tscn")

func egg_hit(egg, hit_by):
	#print("egg "+egg.name+" hit by "+hit_by.name)
	if hit_by.is_in_group("player1"):
		add_to_score1(egg_scores[egg_score_idx1], egg )
		egg_score_idx1=clamp(egg_score_idx1+1,0,egg_scores.size()-1)
	elif hit_by.is_in_group("player2"):
		add_to_score2(egg_scores[egg_score_idx2], egg )
		egg_score_idx2=clamp(egg_score_idx2+1,0,egg_scores.size()-1)
	if egg.bird and weakref(egg.bird).get_ref():
		egg.bird.remove=true 
		if egg.bird.state==3:
			egg.bird.queue_free()

	$SoundEggHit.play()

	egg.queue_free()
	

func standingrider_hit(r, hit_by):
	print("rider "+r.rider+" hit by "+hit_by.name)
	if hit_by.is_in_group("player1"):
		add_to_score1(egg_scores[egg_score_idx1], r )
		egg_score_idx1=clamp(egg_score_idx1+1,0,egg_scores.size()-1)
	elif hit_by.is_in_group("player2"):
		add_to_score2(egg_scores[egg_score_idx2], r )
		egg_score_idx2=clamp(egg_score_idx2+1,0,egg_scores.size()-1)
	r.bird.remove=true
	if r.bird.state==3:
		r.bird.queue_free()
	r.queue_free()

func game_start():
	if not Settings.god_mode:
		Global.cheated=false
	wave=start_wave
	wave_started=false
	p1_lives=start_lives
	score1=start_score
	p2_lives=0
	$PlayerBird2.hide()
	$PlayArea.show()
	$HUD.lives1(p1_lives+1)
	$HUD.lives2(0)
	$HUD.start1()
	$DelayShowPlayer.start()
	wave_setup(wave)
	
func game_start_2():
	if not Settings.god_mode:
		Global.cheated=false
	wave=start_wave
	wave_started=false
	p1_lives=start_lives
	p2_lives=start_lives
	score1=0
	score2=0
	$PlayArea.show()
	$HUD.lives1(p1_lives+1)
	$HUD.lives2(p2_lives+1)
	$HUD.start2()
	$DelayShowPlayer.start()
	wave_setup(wave)

func add_enemy(type, pod, face_to, rider):
	var bird=null
	var i
	if type=="Buzzard":
		bird=BirdBuzzard.instance()
	if type=="Stork":
		bird=BirdStork.instance()
	if type=="Ostrich":
		bird=BirdOstrich.instance()
	if bird:
		bird.npc_arrive(self, pod, face_to, rider)
		#bird.connect("troll", self, "troll_attack")

	return bird.get_node("Animations")
		
func wave_setup(w):
	seed(w+1000)
	Global.wave=w
	Global.gotowave=0
	wave_rng.seed=1000+w
	
	egg_score_idx1=0
	egg_score_idx2=0
	wave=w
	Global.wave=w
	survived=true
	p1team=true
	p2team=true
	gladiator=0
	
	$PlayArea.setup(wave)
	yield( $PlayArea, "playarea_ready")
	print("PlayArea ready")
	
	if wave>=troll_wave:
		$PlayArea/BaseLeft.visible=false
		$PlayArea/BaseLeft/Collider.disabled=true
		$PlayArea/BaseRight.visible=false
		$PlayArea/BaseRight/Collider.disabled=true
		$PlayArea/Troll/Left.disabled=false
		$PlayArea/Troll/Right.disabled=false
	else:
		$PlayArea/Troll/Left.disabled=true
		$PlayArea/Troll/Right.disabled=true
		

	if wave>floor_wave:
		$PlayArea/BaseLeft.scale*=0
		$PlayArea/BaseRight.scale*=0
		
	if wave%5==0:
		for i in range(1,13):
			var rider
			var bird=BirdBuzzard.instance()
			if wave<=10:
				rider="Bounder"
			elif wave>10 and wave<=55:
				rider="Hunter"
			elif wave>=60:
				rider="ShadowLord"
			else:
				bird.see_distance=300
			bird.get_node("SoundFlap").volume_db=-80
			var pos=get_node("EggWavePositions/Egg"+str(i)).global_position

			bird.npc_arrive_pos(self, pos, 1, rider)
			var egg=Egg.instance()
			egg.bird=bird
			egg.connect("egg_hit", self, "egg_hit")
			egg.hatch_delay+=5
			egg.start_flashing=false
			egg.global_position=pos
			egg.rider=rider
			add_child(egg)
		wave_started=true
		
	$HUD/WaveAnnounce/WaveAnnounce.text="WAVE "+str(wave) 
	$HUD/WaveAnnounce/TitleAnnounce.text=""
	$HUD/WaveAnnounce/PrepareAnnounce.text=""
	if wave==1:
		$HUD/WaveAnnounce/TitleAnnounce.text="BUZZARD BAIT!"
		$HUD/WaveAnnounce/PrepareAnnounce.text="PREPARE TO JOUST"
		$Animations.play("wave1_flames")
	elif wave==8:
		$HUD/WaveAnnounce/PrepareAnnounce.text="BEWARE OF THE \"UNBEATABLE?\" PTERODACTYL"
	elif (wave)%5==2:
		if Global.players==1:
			$HUD/WaveAnnounce/PrepareAnnounce.text="SURVIVAL WAVE"
		elif Global.players==2:
			$HUD/WaveAnnounce/PrepareAnnounce.text="TEAM WAVE"
		$Animations.play("wave2_flames")

	elif wave%5==0:
		$HUD/WaveAnnounce/PrepareAnnounce.text="EGG WAVE"
		$Animations.play("wave2_flames")
	
	elif wave%5==4:
		if Global.players==2:
			$HUD/WaveAnnounce/PrepareAnnounce.text="GLADIATOR WAVE"

	if wave>=3:
		$Animations.play("wave3_flames")
	
	$HUD/Animations.play("wave_intro_fade")
	print("starting wave intro text")
	
	if wave==floor_wave:
		$Animations.queue("remove_floor")
		#yield($Animations, "animation_finished")
	
	if test_wave:
		return setup_test_wave()
		
	$WaveStartDelay.start()
	yield($WaveStartDelay, "timeout")
	if Global.hat_mode and (wave-1)%10==0:
		var h=Hat.instance()
		add_child(h)
		h.global_position=Vector2(hat_rng.randi()%int(Global.screen_size.x),-1)
	var pod
	var pod_idx
	var pods
	var pteros=0
	if wave>=8 and wave%5==3:
		if wave<18:
			pteros=1
		elif wave<43:
			pteros=2
		else:
			pteros=3
		
	for i in pteros:
		var p=Ptero.instance()
		p.index=i
		p.rng=ptero_rng
		p.wave=wave
		p.started_with_wave=true
		add_child(p)
		if Global.players==1:
			p.get_node("Ptero").players=[$PlayerBird/Bird]
		elif Global.players==2:
			p.get_node("Ptero").players=[$PlayerBird/Bird, $PlayerBird2/Bird]
		p.start(get_node("PteroStarts/Start"+str(randi()%4+1) ).global_position)

	if $PlayArea.topmiddle.has(wave) or wave>90:
		pods=[1,2,3]
	else:
		pods=[1,2,3,4]
	if wave%5!=0:
		var riders=[]
		var w0=(wave-1)%90
		if bounders.size()>w0:
			for i in range(0,bounders[w0]):
				riders.append( "Bounder")
		if hunters.size()>w0:
			for i in range(0,hunters[w0]):
				if riders.size()>0:
					riders.insert( wave_rng.randi()%riders.size(), "Hunter")
				else:
					riders.append( "Hunter" )
		if shadowlords.size()>w0:
			for i in range(0,shadowlords[w0]):
				if riders.size()>0:
					riders.insert( wave_rng.randi()%riders.size(), "ShadowLord")
				else:
					riders.append("ShadowLord")
		print(riders)
		var lastpod=-1
		for i in range(riders.size()):
			print("rider "+str(i))
			var rider=riders[i]
			var mount="Buzzard"
			
			# Create a list of pods that aren't the same as the last one, 
			# and don't have a player too near
			var pods_available=[]
			while pods_available.size()==0:
				for pi in pods:
					if pi==lastpod:
						continue
					var birds_in_pod=get_node("/root/World/Pods/PodOccupied"+str(pi) ).get_overlapping_bodies()
					var players_in_pod=0
					for j in birds_in_pod:
						if j.is_in_group("player"):
							players_in_pod+=1
					if players_in_pod>0:
						continue
					pods_available.append( pi )
				if pods_available.size()==0:
					if $PlayArea.topmiddle.has(wave) or wave>90:
						pods=[1,2,3]
					else:
						pods=[1,2,3,4]
				
			# Pick a random pod
			pod_idx=wave_rng.randi()%pods_available.size()

			pod=pods_available[pod_idx]
			lastpod=pod
			pods.remove(pod_idx)
			if pods.size()==0:
				if $PlayArea.topmiddle.has(wave) or wave>90:
					pods=[1,2,3]
				else:
					pods=[1,2,3,4]
			yield( add_enemy(mount, pod, -1, rider), "animation_finished")
			wave_started=true

	$PteroTimer._stop()
	$PteroTimer._start()

func setup_test_wave():
	var b=$BirdBuzzard
	b.add_to_group("npc")
	b.face(-1)
	b.get_node("HitLegs").polygon[2].y=10
	b.get_node("HitLegs").polygon[3].y=10
	b.will_live=true
	b.owner=self
	b.set_rider("Hunter")
	b.state=b.STATE.PLAYING
	b.remask()
	b.visible=true
	b.is_alive=true

	$PlayerBird.start1($StartPosition.global_position)
	return
	
func _on_Intro_play():
	game_start(	)

func _process(delta):
	if Global.cheated:
		$HUD/Score1.set("custom_colors/font_color", Color(1,0,0,1))
	if wave_started:
		check_wave()

func add_timed_ptero():
	_on_PteroTimer_add_ptero( get_tree().get_nodes_in_group("ptero").size() )
	return
	
func check_wave():
	#print("Enemies "+str(get_tree().get_nodes_in_group("enemy").size()))
	var cheat=false
	cheat=Input.is_action_just_pressed("wave") or Global.gotowave!=0
	if cheat:
		Global.cheated=true
	if get_tree().get_nodes_in_group("enemy").size()==0 or cheat :
		$PteroTimer._stop()
		get_tree().call_group("enemy", "queue_free" )
		get_tree().call_group("ptero", "fly_away" )
		wave_started=false
		if wave%5==2:
			if survived:
				if Global.players==1:
					$HUD/SurvivalAnnounce.text="COLLECT 3000 SURVIVAL POINTS"
					score1+=3000
					$HUD.score1(score1)
					$HUD/PointsAnimations.play("flash_player_1")
				else:
					$HUD/SurvivalAnnounce.text=("BOTH " if p1team and p2team else ("P1 " if p1team else "P2 "))+"COLLECT 3000 TEAM POINTS"
					if p1team:
						score1+=3000
					if p2team:
						score2+=3000
					$HUD.score1(score1)
					$HUD.score2(score2)
					if p1team and p2team:
						$HUD/PointsAnimations.play("flash_both")
					elif p1team:
						$HUD/PointsAnimations.play("flash_player_1")
					else:
						$HUD/PointsAnimations.play("flash_player_2")
				print("you survived")
			else:
				print("no survival points")
				$HUD/SurvivalAnnounce.text="NO SURVIVAL POINTS"
			$HUD/Animations.play("survival_wave_result")
			yield($HUD/Animations, "animation_finished")
		elif Global.players==2 and wave%5==4:
			if gladiator==0:
				$HUD/SurvivalAnnounce.text="NO GLADIATOR POINTS"
			elif gladiator==1:
				$HUD/SurvivalAnnounce.text="P1 3000 GLADIATOR POINTS"				
				score1+=3000
				$HUD.score1(score1)
				$HUD/PointsAnimations.play("flash_player_1")
			elif gladiator==2:
				$HUD/SurvivalAnnounce.text="P2 3000 GLADIATOR POINTS"				
				score2+=3000
				$HUD.score1(score2)
				$HUD/PointsAnimations.play("flash_player_2")
			$HUD/Animations.play("survival_wave_result")
			yield($HUD/Animations, "animation_finished")
		$WaveOverTimer.start()
		print("Waiting to start next wave....")
		yield($WaveOverTimer, "timeout")
		if Global.gotowave:
			wave_setup(Global.gotowave)
		else:
			wave_setup(wave+1)

func _on_PlayerBird_hit(bird):
	if Settings.god_mode and bird.is_in_group("player1"):
		return
	print("PlayerBird Hit "+bird.name)
	var e=Explosion.instance()
	add_child(e)
	e.global_position=bird.global_position
	survived=false

func add_to_score1(points, item):
	var p=Points.instance()
	p.global_position=item.global_position
	
	if item and item.is_in_group("egg"):
		p.set_points_egg(points)
	elif item and item.is_in_group("bird"):
		p.set_points_bird(points)
	else:
		p.set_points(points)
	add_child(p)
	score1+=points
	if not test_highscores and int(score1/20000)>bonus_lives1:
		bonus_lives1+=1
		p1_lives+=1
		$HUD.lives1(p1_lives)	
	$HUD/Score1.text=str(score1)

func add_to_score2(points, item):
	var p=Points.instance()
	p.global_position=item.global_position
	p.set_points(points)
	add_child(p)
	score2+=points
	if not test_highscores and int(score2/20000)>bonus_lives2:
		bonus_lives2+=1
		p2_lives+=1
		$HUD.lives2(p2_lives)	
	$HUD/Score2.text=str(score2)

func change_lives1(lives):
	p1_lives=lives
	$HUD.lives1(p1_lives)
	survived=false
	if p1_lives==0:
		Global.last_wave1=wave
	if (Global.players==1 and p1_lives==0) or (Global.players==2 and p1_lives==0 and p2_lives==0):
		game_over()

func change_lives2(lives):
	p2_lives=lives
	$HUD.lives2(p2_lives)
	if p2_lives==0:
		Global.last_wave2=wave
	if p1_lives==0 and p2_lives==0:
		game_over()
			
func _on_bird_hit(bird, hit_by):
	print("on_bird_hit "+bird.name+" hit by "+hit_by.name)
	var e=Explosion.instance()
	bird.state=bird.STATE.FLYING_OUT
	e.global_position=bird.global_position
	add_child(e)
	if bird.is_in_group("npc"):
		var points=500
		if bird.rider=="Bounder":
			points=500
		elif  bird.rider=="Hunter":
			points=750
		elif  bird.rider=="ShadowLord":
			points=1000	
		if hit_by.is_in_group("player1"):
			add_to_score1(points, bird )
			$SoundCoin.play()
		elif hit_by.is_in_group("player2"):
			add_to_score2(points, bird )
			$SoundCoin.play()
	elif bird.is_in_group("player1"):
		if not Settings.god_mode:
			score1+=50
			change_lives1(p1_lives-1)
			if hit_by.is_in_group("player2"):
				p2team=false
				if gladiator==0:
					gladiator=2
				add_to_score2(2000, bird)	
			$HUD/Score1.text=str(score1)
			egg_score_idx1=0
	elif bird.is_in_group("player2"):
		score2+=50
		change_lives2(p2_lives-1)
		if hit_by.is_in_group("player1"):
			p1team=false
			if gladiator==0:
				gladiator=1
			add_to_score1(2000, bird)
		$HUD/Score2.text=str(score2)
		egg_score_idx2=0

func _on_DebugTimer_timeout():
	#print( get_tree().get_nodes_in_group("flame") )
	pass
	
func _on_Troll_body_entered(bird):
	if not bird.is_in_group("bird"):
		return
	print("troll area entered by "+bird.name)
	var t=Troll.instance()
	t.victim=bird
	t.add_to_group("troll_hand")
	add_child(t)
	pass # Replace with function body.


func _on_PteroTimer_add_ptero(number):
	if number>5:
		$PteroTimer._stop()
		return
		
	var p=Ptero.instance()
	p.index=0
	p.rng=ptero_rng
	p.wave=wave
	p.started_with_wave=false
	add_child(p)
	if Global.players==1:
		p.get_node("Ptero").players=[$PlayerBird/Bird]
	elif Global.players==2:
		p.get_node("Ptero").players=[$PlayerBird/Bird, $PlayerBird2/Bird]
	var i=randi()%4+1
	p.start(get_node("PteroStarts/Start"+str(i) ).global_position)

func _on_DelayShowPlayer_timeout():
	$PlayerBird.start1($StartPosition.global_position)
	$HUD.lives1(p1_lives)
	if Global.players==2:
		$PlayerBird2.start2($StartPosition2.global_position)
		$HUD.lives2(p2_lives)
	$Start.play()
	
