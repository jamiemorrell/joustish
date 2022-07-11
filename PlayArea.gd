extends Node2D

signal playarea_ready

var topleft=[7,8,9,13,14,21,22,23,24,26,27,28,29,41,42,43,44,51,52,53,54,61,62,63,64,71,72,73,74,81,82,83,84]
var topright=[7,8,9,13,14,21,22,23,24,26,27,28,29,41,42,43,44,51,52,53,54,61,62,63,64,71,72,73,74,81,82,83,84]
var topmiddle=[6,7,8,9,13,14,26,27,28,29,33,34,38,39,44,54,64,74,84]
var centre=[9,12,13,14,23,24,26,27,28,29,36,37,38,39,42,43,44,49,52,53,54,59, 62,63,64,69, 72,73,74,79, 82,83,84,89]

func setup(wave):

	var b=$LeftZone.get_overlapping_bodies()
	while b.size()>0:
		yield(get_tree().create_timer(0.1), "timeout")
		b=$LeftZone.get_overlapping_bodies()
	if topleft.has(wave) or (wave>90 and wave%5!=0):
		$Left/Collider.disabled=true
		if $Left.visible:
			$Left/Animations.play("fade_out")
	else:
		$Left/Collider.disabled=false
		if not $Left.visible:
			$Left/Animations.play("fade_in")

	if topright.has(wave) or (wave>90 and wave%5!=0):
		$Right/Collider.disabled=true
		if $Right.visible:
			$Right/Animations.play("fade_out")
	else:
		$Right/Collider.disabled=false
		if not $Right.visible:
			$Right/Animations.play("fade_in")
	
	if topmiddle.has(wave) or (wave>90 and wave%5!=0):
		$TopMiddle/Collider.disabled=true
		if $TopMiddle.visible:
			$TopMiddle/Animations.play("fade_out")
	else:
		$TopMiddle/Collider.disabled=false
		if not $TopMiddle.visible:
			$TopMiddle/Animations.play("fade_in")

	if centre.has(wave) or (wave>90 and wave%5!=0):
		$Centre/Collider.disabled=true
		if $Centre.visible:
			$Centre/Animations.play("fade_out")
	else:
		$Centre/Collider.disabled=false
		if not $Centre.visible:
			$Centre/Animations.play("fade_in")
	
	yield(get_tree().create_timer(0.1), "timeout")	
	emit_signal("playarea_ready")

