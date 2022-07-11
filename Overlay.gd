extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_mute(m):
	$Animations.play("RESET")
	if m:
		$Animations.play("mute")
	else:
		$Animations.play("unmute")

func set_god_mode(m):
	$Animations.play("RESET")
	if m:
		$Animations.play("godon")
	else:
		$Animations.play("godoff")
		

func set_hat_mode(m):
	$Animations.play("RESET")
	if m:
		$Animations.play("haton")
	else:
		$Animations.play("hatoff")
