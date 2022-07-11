extends Node2D

signal add_ptero( number )

var count : int = 0
export var wait_time : int = 60
export var step_time : int = 2
export var min_time : int = 1

func _ready():
	pass # Replace with function body.

func _start( wait : int = wait_time, step : int = step_time, mini : int = min_time ):
	print("ptero wait=",wait)
	$Timer.wait_time=wait
	$Timer.start()
	wait_time = wait
	step_time = step
	min_time = mini

func _stop():
	$Timer.stop()

func _on_Timer_timeout():
	emit_signal("add_ptero", count)
	if wait_time == step_time:
		return
	count+=1
	
	wait_time = clamp( wait_time-step_time, min_time, wait_time )
	print(wait_time)
	$Timer.wait_time=wait_time
	$Timer.start()
