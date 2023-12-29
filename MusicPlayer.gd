extends AudioStreamPlayer2D

signal beat(last_reported_beat)

var song_position: float = 0.0
var song_position_in_beats = 0
var ping_leeway = 0.5
var seconds_per_beat = 60.0 / 84 # Magic number
var beats_before_start = 0.0
var last_reported_beat = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if playing:
		song_position = get_playback_position() + AudioServer.get_time_since_last_mix()
		song_position -= AudioServer.get_output_latency()
		song_position_in_beats = int(floor(song_position / seconds_per_beat)) + beats_before_start
		_report_beat()
		
func _report_beat() -> void:
	if last_reported_beat < song_position_in_beats - ping_leeway:
		beat.emit(song_position_in_beats)
		last_reported_beat = song_position_in_beats
