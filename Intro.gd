extends Node2D

var screen : int = 1
var screens : int = 2
var screen2_ready : bool = false

func _ready():
	$Screen1/Version.text=Global.version
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Screen1/Label2.text='"'+OS.get_name()+'"'
	$Screen2.hide()
	$Screen1.show()
	
	Global.connect("updated_highscores", self, "update_high_scores")
	$Screen2/Score1/Name.text=""
	$Screen2/Score1/Score.text=""
	$Screen2/TodayScore1/Name.text=""
	$Screen2/TodayScore1/Score.text=""
	var y=$Screen2/Score1.position.y+30
	for i in range(2,11):
		var newNode = $Screen2/Score1.duplicate()
		newNode.get_node("Pos").text=str(i)+")"
		newNode.get_node("Score").text=""
		newNode.get_node("Name").text=""
		newNode.name="Score"+str(i)
		newNode.position.y=y
		$Screen2.add_child(newNode)
		var newNode2 = $Screen2/TodayScore1.duplicate()
		newNode2.get_node("Pos").text=str(i)+")"
		newNode2.get_node("Score").text=""
		newNode2.get_node("Name").text=""
		newNode2.name="TodayScore"+str(i)
		newNode2.position.y=y
		$Screen2.add_child(newNode2)
		y+=30

	if Global.first_load:
		if OS.get_name()=="HTML5":
			var js="document.getElementById('canvas').focus()"
			JavaScript.eval( js )
		$Overlay.set_mute(!Settings.enable_sound)
		Global.first_load=false
	else:
		update_high_scores()
		
		show_screen(2)

	Global.get_high_scores()
	
	if OS.get_name()=="HTML5":
		$Screen1/StartText.hide()
		$Screen1/WebButtons.show()
	else:
		$Screen1/WebButtons.hide()
		$Screen1/StartText.show()

func _process(_delta):
	if Input.is_action_just_pressed('ui_select') or Input.is_action_just_pressed('start1'):
		_on_Player1Button_pressed()
	if Input.is_action_just_pressed('start2'):
		_on_Player2Button_pressed()
	if OS.get_name()!="HTML5" and  Input.is_action_just_pressed('ui_cancel'):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
	if Input.is_action_just_pressed("toggle_fullscreen"):
		Settings.toggle_fullscreen()
	if Input.is_action_just_pressed("mute"):
		Settings.toggle_sound()
		$Overlay.set_mute(!Settings.enable_sound)
	if Input.is_action_just_pressed("hat_mode"):
		Global.hat_mode=not Global.hat_mode
		$Overlay.set_hat_mode(Global.hat_mode)
		
func _on_Player1Button_pressed():
	Global.players=1
	Global.last_score1=0
	Global.last_score2=0
	Global.last_wave1=0
	Global.last_wave2=0
	get_tree().change_scene("res://World.tscn")

func _on_Player2Button_pressed():
	Global.players=2
	Global.last_score1=0
	Global.last_score2=0
	Global.last_wave1=0
	Global.last_wave2=0
	get_tree().change_scene("res://World.tscn")

func _on_ScreenTimer_timeout():
	show_screen(screen+1)
	
func show_screen(n ):
	if n==2 and not screen2_ready:
		return
		
	if n>screens:
		n=1
	get_node("Screen"+str(screen)).hide()
	get_node("Screen"+str(n)).show()
	screen=n

func update_high_scores():

	print("update high scores")

	for i in range(1,11):
		if i<=Global.table.size():
			get_node("Screen2/Score"+str(i)+"/Name").text=Global.table[i-1]["name"]
			get_node("Screen2/Score"+str(i)+"/Score").text=str(Global.table[i-1]["score"])
		if i<=Global.today_table.size():
			get_node("Screen2/TodayScore"+str(i)+"/Name").text=Global.today_table[i-1]["name"]
			get_node("Screen2/TodayScore"+str(i)+"/Score").text=str(Global.today_table[i-1]["score"])
	
	screen2_ready=true
