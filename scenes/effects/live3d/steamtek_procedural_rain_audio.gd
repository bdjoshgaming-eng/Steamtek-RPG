class_name SteamtekProceduralRainAudio
extends AudioStreamPlayer

@export var duration_seconds := 4.0
@export var sample_rate := 22050

var _generated := false


func _ready() -> void:
	if not _generated:
		stream = _generate_rain_loop()
		_generated = true


func _generate_rain_loop() -> AudioStreamWAV:
	var samples := int(duration_seconds * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var prev := 0.0
	var filter_coeff := 0.7
	for i in samples:
		var noise := randf_range(-1.0, 1.0)
		prev = prev * filter_coeff + noise * (1.0 - filter_coeff)
		var shaped := prev * 0.22
		var fade_in := clampf(float(i) / (sample_rate * 0.5), 0.0, 1.0)
		var fade_out := clampf(float(samples - i) / (sample_rate * 0.5), 0.0, 1.0)
		shaped *= fade_in * fade_out
		var sample_int := clampi(int(shaped * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = int(sample_rate * 0.5)
	wav.loop_end = samples - int(sample_rate * 0.5)
	return wav
