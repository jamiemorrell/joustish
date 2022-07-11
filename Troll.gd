extends Node2D

var victim=null
var grabbing=false
var grabbed=false
var start_pos
var grab_pos

func _ready():
	hide()
	if victim and victim.state==victim.STATE.PLAYING:
		print("starting troll grab")
		grab_at(victim)
	else:
		print("bird not in play")
		queue_free()

func free_bird_troll(bird):
	print("I am "+name+". Bird "+bird.name+" wants to be forgot")
	if victim==bird:
		print("remove troll hand "+name)
		queue_free()

func on_bird_hit(bird, hit_by):
	print("troll told bird "+bird.name+" killed by "+hit_by.name)
	bird.troll_coming=false
	queue_free()
	
func grab_at(bird):
	if bird and weakref(bird).get_ref() :
		if bird.troll_coming:
			print("give up")
			queue_free()
			return
		bird.connect("birdhit", self, "on_bird_hit")
		grabbing=true
		if bird.facing<0:
			scale.x*=-1
		var pos=bird.global_position
		global_position=pos
		start_pos=pos
		bird.troll_coming=true
		print("grab at "+bird.name)
		show()
		$Animations.play("grab")
	else:
		queue_free()
	
func grab():
	
	if victim and weakref(victim).get_ref() and abs(victim.global_position.x-global_position.x)<10 and abs(global_position.y-victim.global_position.y)<10:
		victim.state=victim.STATE.GRABBED
		global_position.x=victim.global_position.x
		global_position.y=$"/root/World/PlayArea/Fire".margin_top+55
		grabbed=true
		grab_pos=victim.global_position
		victim.troll_coming=false
		grabbing=false
		$Animations.play("grabbed")
		return true
		
	return false

func let_go():
	victim.state=victim.STATE.PLAYING
	miss()
	
func miss():
	grabbed=false
	grabbing=false
	victim.troll_coming=false
	$Animations.play("missed")

func last_grab():
	if not grab():
		miss()
		
func _process(delta):
	if not victim or not weakref(victim).get_ref() or (victim.state!=victim.STATE.PLAYING and victim.state!=victim.STATE.GRABBED):
		print("troll's bird died!")
		if  victim and weakref(victim).get_ref():
			print("bird still exists")
			victim.troll_coming=false
		print("Grabbed",grabbed)
		print("grabbing", grabbing)
		if grabbed: 
			print("Playing miss animation")
			$Animations.play("missed")
			yield($Animations, "animation_finished")
		queue_free()
		return
		
	if grabbing:
		var v=victim.global_position
		var troll_area_left=$"/root/World/PlayArea/Troll/Left"
		var troll_area_right=$"/root/World/PlayArea/Troll/Right"
	
		# If the bird moves away from the lava pit, give up
		if v.x>(troll_area_left.global_position.x+troll_area_left.shape.extents.x/2) and v.x<(troll_area_right.global_position.x-troll_area_right.shape.extents.x/2) :
			miss()
			return
			
		global_position.x+=(300*delta) if v.x>global_position.x else (-300*delta)
		if global_position.y>v.y:
			global_position.y-=(200*delta)
		elif global_position.y<v.y:
			global_position.y+=(200*delta)		
		return
		
	if grabbed:
		if victim.state!=victim.STATE.GRABBED:
			victim.troll_coming=false
			queue_free()
			return
		var pos=victim.global_position
		if (grab_pos.y-pos.y)>40:
			let_go()
		global_position=pos
		
			
	if not victim or not weakref(victim).get_ref() :
		hide()
		queue_free()
		return
