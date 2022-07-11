extends Node2D

var p1_lives=3


func screen_metrics():
	print("                 [Screen Metrics]")
	print("            Display size: ", OS.get_screen_size())
	print("   Decorated Window size: ", OS.get_real_window_size())
	print("             Window size: ", OS.get_window_size())
	print("        Project Settings: Width=", ProjectSettings.get_setting("display/window/size/width"), " Height=", ProjectSettings.get_setting("display/window/size/height")) 
	print(OS.get_window_size().x)
	print(OS.get_window_size().y)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	screen_metrics()
	$PlayerBird/Bird.face(-1)
	$PlayerBird.start1()
	$Ptero/Ptero.players=[$PlayerBird/Bird]
	$Ptero/Ptero.face(-1)
	$Ptero.start( $PteroStarts/Start1.global_position )
	
	$PteroTimer.start()
	
func _on_PteroTimer_add_ptero(num):
	print("asked to add ptero ",num)
	
