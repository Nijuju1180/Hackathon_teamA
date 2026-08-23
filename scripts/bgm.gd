extends Node
## BGMの再生。Autoload「Bgm」として常駐する。
## シーン側のノードで鳴らすと、SceneTransition のシーン入れ替えで鳴り切る前に消えるため、
## 再生はここに集約する。

const TRACKS := {
	&"title": preload("res://assets/MusMus-BGM-021.mp3"),
	&"game": preload("res://assets/2_23_AM.mp3"),
}

## 曲ごとの音量(dB)。0 が元の音量、-6 でおよそ半分、+6 でおよそ2倍。ここを書き換えて調整する。
const VOLUMES_DB := {
	&"title": 0.0,
	&"game": 0.0,
}

## BGM全体の音量(dB)。個別の値に加算される。
const MASTER_VOLUME_DB := 0.0

## 曲を切り替えるときのフェードアウト秒数。SceneTransitionの暗転秒数に合わせる。
const FADE_SECONDS := 0.35

var _player: AudioStreamPlayer
var _current_track: StringName = &""


func _ready() -> void:
	# ポーズ中や遷移中でも鳴らし続ける
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	for track: AudioStream in TRACKS.values():
		if track is AudioStreamMP3:
			track.loop = true


## 指定した曲をループ再生する。すでにその曲を再生中なら何もしない。
func play(track: StringName) -> void:
	if not TRACKS.has(track):
		push_error("Bgm: 未登録のBGMです name=%s" % track)
		return
	if track == _current_track:
		return
	_current_track = track

	var target_volume := MASTER_VOLUME_DB + float(VOLUMES_DB.get(track, 0.0))
	var tween := create_tween()
	if _player.playing:
		tween.tween_property(_player, "volume_db", target_volume - 24.0, FADE_SECONDS)
	tween.tween_callback(_start.bind(TRACKS[track], target_volume))


func _start(stream: AudioStream, volume_db: float) -> void:
	_player.stream = stream
	_player.volume_db = volume_db
	_player.play()


## 再生を止める。
func stop() -> void:
	_current_track = &""
	_player.stop()
