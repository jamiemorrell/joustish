extends Label


var bitmapFont: BitmapFont

func _ready():
	bitmapFont=BitmapFont.new()
	bitmapFont.add_texture(preload("res://fonts/numberfont.png"))
	var start=ord("0")
	for i in range(0, 10):
		var c=start+i
		bitmapFont.add_char(c, 0, Rect2(i*15+3,0,9,15), Vector2(0,0), 15)
		theme=Theme.new()
		theme.default_font=bitmapFont
