extends Node2D

func text(msg):
	$Announce.text=msg
	$Animations.play("wave_title_fade")
	return $Animations

func start1():
	$Score1.text="0"
	$Score1.show()
	$Lives1.show()
	$Score2.hide()
	$Lives2.hide()
	show()

func start2():
	$Score1.text="0"
	$Score2.text="0"
	$Score1.show()
	$Lives1.show()
	$Score2.show()
	$Lives2.show()
	show()
	
func score1(s):
	$Score1.text=str(s)
	
func score2(s):
	$Score2.text=str(s)

func lives1(p):
	print("lives1 "+str(p))
	for i in range(1,6):
		var node=get_node("Lives1/Sprite"+str(i))
		if i>=p:
			node.hide()
		else:
			node.show()

func lives2(p):
	print("lives2 "+str(p))
	for i in range(1,6):
		var node=get_node("Lives2/Sprite"+str(i))
		if i>=p:
			node.hide()
		else:
			node.show()
