extends Node2D

signal hit(bird)

var started=false
var game_over=false
var debounce_left=false
var debounce_right=false

func _ready():
	$Bird.remove_from_group("enemy")
	game_over=false
	hide()

func start1(pos=null):
	if pos!=null:
		global_position=pos
	show()
	started=true
	$Bird.set_rider("Player1")
#	$Bird.connect("hit",self,"player1_hit")
	$Bird.remask()
	$Bird.show()
	$Bird.state=$Bird.STATE.PLAYING

func start2(pos=null):
	if pos!=null:
		global_position=pos
	show()
	started=true
	$Bird.set_rider("Player2")
	$Bird.face(-1)
#	$Bird.connect("hit",self,"player2_hit")
	$Bird.remask()
	$Bird.show()
	$Bird.state=$Bird.STATE.PLAYING
	
func player1_hit():
	print("Ouch!")
	$Bird.state=$Bird.STATE.FLYING_OUT
	emit_signal("hit", $Bird)

func player2_hit():
	print("Ouch!")
	$Bird.state=$Bird.STATE.FLYING_OUT
	emit_signal("hit", $Bird)
	
func set_game_over():
	started=false
	game_over=true
	
func get_input():
	var bird=$Bird
	
	if $Bird.is_in_group("player1"):
		if $Bird.state==$Bird.STATE.PLAYING or $Bird.state==$Bird.STATE.WAITING:
			if not (debounce_right or debounce_left) and (Input.is_action_pressed('ui_right') or Input.is_action_pressed('p1right') ):
				bird.right()
				debounce_right=true
				debounce_left=false
				$DebounceRight.start()
			if not (debounce_left or debounce_right) and (Input.is_action_pressed('ui_left') or Input.is_action_pressed('p1left') ):
				bird.left()
				debounce_left=true
				debounce_right=false
				$DebounceLeft.start()
		if Input.is_action_just_pressed('suicide1'):
			player1_hit()
		if Input.is_action_just_pressed('ui_select') or Input.is_action_just_pressed('ui_up') or Input.is_action_pressed('p1flap'):
			bird.flap()

	if $Bird.is_in_group("player2"):
		if $Bird.state==$Bird.STATE.PLAYING or $Bird.state==$Bird.STATE.WAITING:
			if not debounce_right and ( Input.is_action_pressed('p2right') ):
				bird.right()
				debounce_right=true
				$DebounceRight.start()
			if not debounce_left and ( Input.is_action_pressed('p2left') ):
				bird.left()
				debounce_left=true
				$DebounceLeft.start()
		if Input.is_action_just_pressed('suicide1'):
			player2_hit()
		if Input.is_action_pressed('p2flap'):
			bird.flap()
			
func _physics_process(delta):
	if $Bird.state==$Bird.STATE.PLAYING or $Bird.state==$Bird.STATE.GRABBED or $Bird.state==$Bird.STATE.WAITING:
		get_input()



func _on_Bird_ready_player1():
	if $"/root/World".p1_lives<=0 or game_over:
		return
	print("Reposition")
	var pods
	if $"/root/World/PlayArea".topmiddle.has(Global.wave) or (Global.wave>90 and Global.wave%5!=0):
		pods=[1,2,3]
	else:
		pods=[1,2,3,4]
		
	var pod
	var pos
	var sitters=1
	var count=10
	while sitters>0 and count>0:
		pod=pods[randi()%pods.size()]
		sitters=get_node("/root/World/Pods/PodOccupied"+str(pod)).get_overlapping_bodies().size()
		print(pod, " ", pods.size(), " ", count," ", sitters)
		count-=1
	pos=get_node("/root/World/Pods/Pod"+str(pod)).global_position
	print("Sitters on pod "+str(pod)+"="+str(sitters) )
	$Bird.player_arrive(pod, 1)
	$Bird.set_rider("Player1")
	$Bird.state=$Bird.STATE.ARRIVING

func _on_Bird_ready_player2():
	if $"/root/World".p2_lives<=0 or game_over:
		return
	print("Reposition")
	
	var pods
	if $"/root/World/PlayArea".topmiddle.has(Global.wave):
		pods=[1,2,3]
	else:
		pods=[1,2,3,4]
		
	var pod
	var pos
	var sitters=1
	while sitters>0:
		pod=pods[randi()%pods.size()]
		sitters=get_node("/root/World/Pods/PodOccupied"+str(pod)).get_overlapping_bodies().size()
	pos=get_node("/root/World/Pods/Pod"+str(pod)).global_position
	$Bird.player_arrive(pod, 1)
	$Bird.set_rider("Player2")
	$Bird.state=$Bird.STATE.ARRIVING
	
func _on_DebounceRight_timeout():
	debounce_right=false

func _on_DebounceLeft_timeout():
	debounce_left=false
	
