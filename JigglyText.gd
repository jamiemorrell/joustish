extends Node2D


export(String) var text :  = "Text"
export(float) var offset :  = 0
export(bool) var link_to_x : = false
export(DynamicFontData) var font

func _ready():
	print($Label.rect_size)
	$Label.text=text
	$Label.add_font_override("font", font)

func _process(delta):
	pass
