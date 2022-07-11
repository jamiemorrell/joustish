extends Node2D

signal killed( ptero, player)

var Explosion=preload("res://Explosion.tscn")
var Points=preload("res://Points.tscn")

var facing : int =1
var rng
var wave : int =1
var index : int =0
var velocity :Vector2 =Vector2(200,10)
var started_with_wave : bool = false


func _ready():
	#If we're testing one scene....
	if not rng:
		rng=RandomNumberGenerator.new()
	rng.seed=wave*1002+index
	return

func start( pos : Vector2 ):
	
	$Ptero.global_position=pos
	if pos.x>Global.screen_size.x:
		$Ptero.face(-1)
		$Ptero.velocity=Vector2(-300,0)
	
	$StartTimer.wait_time=0.3+index*2
	$StartTimer.start()
	$ScreechTimer.wait_time=1+rng.randi()%4
	$ScreechTimer.start()

func _on_Mouth_body_entered(body):
	print("mouth hit "+body.name)
	if body.is_in_group("player") and body.state==body.STATE.PLAYING:
		print("ptero says a player got him")
		emit_signal("killed", self, body)
		var p=$".."
		if body.is_in_group("player1"):
			p.add_to_score1( 1000, body)
		elif body.is_in_group("player2"):
			p.add_to_score2( 1000, body)		
		die()

func fly_away():
	$Ptero.fly_away() 
	
func _on_ScreechTimer_timeout():
	$Animation.play("screech")
	$ScreechTimer.wait_time=1+rng.randf()*3
	$ScreechTimer.start()

func _on_StartTimer_timeout():
	$Ptero.started=true
	$Animation.play("screech")
	$Ptero.show()

func die():
	$Ptero.die()
	$Animation.play("death")
