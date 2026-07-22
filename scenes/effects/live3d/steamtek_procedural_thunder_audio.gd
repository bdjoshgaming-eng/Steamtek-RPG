class_name SteamtekProceduralThunderAudio
extends AudioStreamPlayer

@export var duration_seconds := 2.5
@export var sample_rate := 22050

var _generated := false


func _ready() -> void:
	if not _generated:
		stream = _generate_thunder()
		_generated = true


func _generate_thunder() -> AudioStreamWAV:
	var samples := int(duration_seconds * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var prev := 0.0
	var prev2 := 0.0
	var filter_a := 0.85
	var filter_b := 0.82
	for i in samples:
		var t := float(i) / sample_rate
		var noise := randf_range(-1.0, 1.0)
		prev = prev * filter_a + noise * (1.0 - filter_a)
		prev2 = prev2 * filter_b + prev * (1.0 - filter_b)
		var envelope := 0.0
		if t < 0.05:
			envelope = t / 0.05
		elif t < 0.15:
			envelope = 1.0
		elif t < 0.4:
			envelope = lerpf(1.0, 0.6, (t - 0.15) / 0.25)
		else:
			envelope = 0.6 * exp(-(t - 0.4) * 2.2)
		var rumble := sin(t * TAU * 28.0) * 0.08 * exp(-t * 1.5)
		var shaped := (prev2 * 0.35 + rumble) * envelope
		var sample_int := clampi(int(shaped * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav
