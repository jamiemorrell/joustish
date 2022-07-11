extends Node

var gotowave=""
var goto=false

func  _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	print("pause ready")
	
func _process(delta):
	if Global.typing:
		return
	if Input.is_action_just_pressed('pause'):
		print("pause",get_tree().paused)
		#get_tree().paused=!get_tree().paused
		if not get_tree().paused:
			$"../PauseScreen/Animations".play("pause")
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused=true
		else:
			$"../PauseScreen/Animations".play("unpause")
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			yield( $"../PauseScreen/Animations", "animation_finished")
			get_tree().paused=false
	if Input.is_action_just_pressed('ui_cancel'):
		if get_tree().paused:
			get_tree().paused=false
		get_tree().change_scene("res://Intro.tscn")
	if Input.is_action_just_pressed("toggle_fullscreen"):
		Settings.toggle_fullscreen()
	if Input.is_action_just_pressed("godmode"):
		Settings.god_mode=not Settings.god_mode
		if Settings.god_mode:
			Global.cheated=true
		print("God mode: "+("on" if Settings.god_mode else "off"))
		$"/root/World/Overlay".set_god_mode( Settings.god_mode)
	if Input.is_action_just_pressed("mute"):
		Settings.toggle_sound()
		$"/root/World/Overlay".set_mute(not Settings.enable_sound)
	if Input.is_action_just_pressed("add_ptero"):
		Global.cheated=true
		$"..".add_timed_ptero()
	if Input.is_action_just_pressed("goto"):
		goto=true
	
	if goto:
		for i in range(10):
			if Input.is_action_just_pressed("number"+str(i)):
				gotowave+=str(i)
		if gotowave.length()==3:
			Global.cheated=true
			Global.gotowave=int(gotowave)
			gotowave=""
			goto=false
			
		
