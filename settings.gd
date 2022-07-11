extends Node

var enable_sound=true
var fullscreen=true
var god_mode=false

var settings_file = "user://settings.save"

func _ready():
	self.load()
	print("Loaded settings")

func save():
	var f = File.new()
	f.open(settings_file, File.WRITE)
	f.store_var(enable_sound)
	f.store_var(fullscreen)
	f.close()

func load():
	var f = File.new()
	if f.file_exists(settings_file):
		f.open(settings_file, File.READ)
		set_sound( f.get_var() )
		set_fullscreen( f.get_var() )
		f.close()
		
func set_sound(m):
		enable_sound=m
		var master_sound = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_mute(master_sound, !m )
		self.save()
		
func toggle_sound():
	set_sound(not enable_sound)

func toggle_fullscreen():
	set_fullscreen(not fullscreen)
	
func set_fullscreen(f):
	fullscreen=f
	OS.window_fullscreen = f
	self.save()
