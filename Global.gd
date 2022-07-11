extends Node

signal updated_highscores

# SilentWolf key = eN8w33WV3H8cgx8AanMrq4XjWrJ4KZLW62Kbh0T9
var first_load : bool = true
var test_highscores : bool = false
var god_mode : bool  =false
var hat_mode : bool = false
var players=1
var version="0.81"
var cheated : bool = false
var wave
var screen_size=Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))
var gotowave=0
var db : FirebaseDatabase 
var highscore 
var last_score1 : int = 0
var last_score2 : int = 0
var last_wave1 : int = 0
var last_wave2 : int = 0
var table=[]
var today_table=[]
var typing=false

var highscoreref 

var firebase_config = {
	"apiKey": "AIzaSyB_1MvyWGGZ3S_Lj73hc44oEqARk_2e_74",
	"authDomain": "joustish.firebaseapp.com",
	"projectId": "joustish",
	"databaseURL": "https://joustish-default-rtdb.europe-west1.firebasedatabase.app/",
	"storageBucket": "joustish.appspot.com",
	"messagingSenderId": "646177877556",
	"appId": "1:646177877556:web:99f04677799b08c2316461"
}

func _ready():
	firebase.initialize_app(firebase_config)
	db = firebase.database()
	highscoreref = db.get_reference_lite("joustish/highscores")
	get_high_scores()

func get_high_scores():
	var highscores=yield(highscoreref.fetch(), "completed")
	if highscores is FirebaseError:
		print("firebase error")
		return FirebaseError

	var now=OS.get_datetime()
	var today=OS.get_unix_time_from_datetime({ "year": now.year, "month": now.month, "day": now.day})

	highscores=highscores.value()
	print("global.got ", highscores)
	var tmp_today_table=[]
	var tmp_table=[]
	for i in highscores.keys():
		tmp_table.append(highscores[i])
		var stamp=int(i.split("-")[0])
		tmp_table[-1].stamp=stamp
		tmp_table[-1].key=i
		if stamp>=today:
			tmp_today_table.append(tmp_table[-1])

	tmp_table.sort_custom(self, "sort_highscores")
	tmp_today_table.sort_custom(self, "sort_highscores")
	
	today_table=tmp_today_table.slice(0,9)
	table=tmp_table.slice(0,9)
	
	# Tidy up scores out of top 10 and from before today
	for i in tmp_table.size():
		if tmp_table[i].score<table[-1].score and tmp_table[i].stamp<today:
			var old_score_ref = db.get_reference_lite("joustish/highscores/"+tmp_table[i].key)
			yield(old_score_ref.remove(), "completed")
			print("removed ", tmp_table[i].key)

	emit_signal("updated_highscores")
	
	return { "alltime": table, "today": today_table}

func add_high_score(entry):
	var key=str(OS.get_unix_time( ))+"-"+entry.name
	table.append(entry)
	today_table.append(entry)
	if not test_highscores:
		highscoreref.update({key : entry } )
	table.sort_custom(self, "sort_highscores")
	table=table.slice(0,9)
	today_table.sort_custom(self, "sort_highscores")
	today_table=today_table.slice(0,9)
	
func sort_highscores(a, b):
	return a["score"] > b["score"];
