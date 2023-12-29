extends Node

@export var arrow_scene: PackedScene
@export var FALL_SPEED: float

var BPM: float
var TIME_NUMERATOR: float
var QUARTER_NOTES_PER_SECOND: float
var QUARTER_NOTE_DURATION: float
var music_has_intro

var PERFECT_TIMING_Y: float
var PERFECT_POINTS: float = 1000
var GOOD_POINTS: float = 800
var OK_POINTS: float = 500
var MAX_SCORE: float

var LOADING_DELAY_OFFSET: float = 0.014

var game_has_started = false
var play_countdown_sfx = false

# Obviously this is hard-coded for now...
var arrow_timers: Array = [
	["right",2],["right",1],["down",1],
	["left",2],["right",1],["left",1],
	["left",2],["down",1],["down",1],
	["left",2],["right",1],["right",1],
	["left",2],["right",1],["left",1],
	["left",2],["right",1],["left",1],
	["left",1],["down",1],["right",1],["left",1],
	["left",2],["right",1],["left",1],
	["left",2],["left",1],["down",1],
	["right",2],["left",1],["down",1],
	["right",2]]
var arrow_timers_index = 0

var curr_combo = 0
var max_combo = 0
var score = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ArrowTimer.timeout.connect(_on_arrow_timer_timeout)
	$StartTimer.timeout.connect(_on_start_timer_timeout)
	$EndTimer.timeout.connect(_on_end_timer_timeout)
	$MusicStartTimer.timeout.connect(_on_music_start_timer_timeout)
	$Player.hit.connect(_on_player_hit)
	$Player.miss.connect(_on_player_miss)
	
	#TODO: Change these to be parsed from specific level data
	$ArrowTimer.wait_time = 0 # units, not seconds
	$EndTimer.wait_time = 40 # no need to convert
	music_has_intro = false
	
	BPM = 84
	TIME_NUMERATOR = 4
	QUARTER_NOTES_PER_SECOND = BPM / 60
	QUARTER_NOTE_DURATION = 60 / BPM
	
	if music_has_intro:
		$ArrowTimer.wait_time /= QUARTER_NOTES_PER_SECOND
		print($ArrowTimer.wait_time)
	
	PERFECT_TIMING_Y = get_node("Player/LeftInputHitbox/CollisionShape2D").position.y
	MAX_SCORE = PERFECT_POINTS * arrow_timers.size()
	
	new_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !game_has_started:
		if $MusicStartTimer.time_left <= TIME_NUMERATOR * QUARTER_NOTE_DURATION:
			var countdown_text = str(ceil($MusicStartTimer.time_left / QUARTER_NOTE_DURATION) - 1)
			if countdown_text == "0":
				countdown_text = "GO!"
			if countdown_text != $HUD/CountdownLabel.text:
				if countdown_text == "GO!":
					$CountdownPlayer.stream = load("res://sound/countdown_high.wav")
				$CountdownPlayer.playing = true
			$HUD/CountdownLabel.text = countdown_text
			if $MusicStartTimer.time_left == 0:
				game_has_started = true
				$HUD/CountdownLabel.text = ""
	$HUD/ScoreLabel.text = str(score)

	
func new_game():
	$StartTimer.start()
	
func game_over():
	# Display final score.
	var score_percentage = score / MAX_SCORE
	if score_percentage >= 0.9:
		$HUD/GameOverMenu/FinalRankLabel.text = "Rank S"
	elif score_percentage >= 0.8:
		$HUD/GameOverMenu/FinalRankLabel.text = "Rank A"
	elif score_percentage >= 0.7:
		$HUD/GameOverMenu/FinalRankLabel.text = "Rank B"
	elif score_percentage >= 0.6:
		$HUD/GameOverMenu/FinalRankLabel.text = "Rank C"
	else:
		$HUD/GameOverMenu/FinalRankLabel.text = "Rank D"
		
	$HUD/GameOverMenu.visible = true
	#TODO: Show exit and play-again buttons.

func _on_start_timer_timeout() -> void:
	$EndTimer.start()
	
	var first_arrow_delay = (PERFECT_TIMING_Y + 60) / FALL_SPEED
	var countdown_delay = QUARTER_NOTE_DURATION * TIME_NUMERATOR

	if (countdown_delay < first_arrow_delay):
		$ArrowTimer.wait_time = 0.00001
		$MusicStartTimer.wait_time = first_arrow_delay
	else:
		$ArrowTimer.wait_time = countdown_delay - first_arrow_delay
		$MusicStartTimer.wait_time = countdown_delay
	
	$ArrowTimer.start()
	$MusicStartTimer.start()
	
func _on_end_timer_timeout() -> void:
	game_over()
	
func _on_music_start_timer_timeout() -> void:
	$MusicPlayer.playing = true

func _on_arrow_timer_timeout() -> void:
	# No more arrows to load
	if arrow_timers_index >= arrow_timers.size():
		return
	
	var arrow = arrow_scene.instantiate()
	
	# Spawn arrow left, middle, or right
	var arrow_spawn_location
	if arrow_timers[arrow_timers_index][0] == "left":
		arrow_spawn_location = get_node("LeftArrowPath/LeftArrowSpawnLocation")
		arrow.rotation -= PI / 2 
	elif arrow_timers[arrow_timers_index][0] == "down":
		arrow_spawn_location = get_node("DownArrowPath/DownArrowSpawnLocation")
		arrow.rotation += PI
	elif arrow_timers[arrow_timers_index][0] == "right":
		arrow_spawn_location = get_node("RightArrowPath/RightArrowSpawnLocation")
		arrow.rotation += PI / 2
	arrow.position = arrow_spawn_location.position

	var velocity = Vector2.DOWN * FALL_SPEED
	arrow.linear_velocity = velocity

	add_child(arrow)
	
	# Get, set and start the timer for next arrow
	
	# Static version for testing
	'''
	var arrow_timer = get_node("ArrowTimer") as Timer
	arrow_timer.wait_time = 0.2
	arrow_timer.start()
	'''
	
	# Enumerated version
	var arrow_timer = get_node("ArrowTimer") as Timer
	arrow_timer.wait_time = arrow_timers[arrow_timers_index][1] / QUARTER_NOTES_PER_SECOND
	arrow_timer.wait_time -= LOADING_DELAY_OFFSET
	arrow_timer.start()
	arrow_timers_index += 1


func _on_player_hit(body) -> void:
	if body == null:
		return
	update_score_and_play_sfx(body)
	update_combo()
	remove_child(body)
	
func _on_player_miss() -> void:
	curr_combo = 0
	print("MISS")

func update_score_and_play_sfx(body: RigidBody2D):
	#TODO: Change to play different sound depending on score
	$HitPlayer.playing = true
	if abs(body.position.y - PERFECT_TIMING_Y) <= 20:
		score += PERFECT_POINTS
		print("PERFECT")
	elif abs(body.position.y - PERFECT_TIMING_Y) <= 50:
		score += GOOD_POINTS
		print("GOOD")
	else:
		score += OK_POINTS
		print("OK")

func update_combo():
	curr_combo += 1
	max_combo = max(curr_combo, max_combo)
