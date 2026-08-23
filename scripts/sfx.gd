extends Node
## 効果音の再生。Autoload「Sfx」として常駐する。
## シーン側のノードで鳴らすと、SceneTransition のシーン入れ替えで鳴り切る前に消えるため、
## 再生はここに集約する。

const SOUNDS := {
	&"decide": preload("res://assets/決定ボタンを押す12.mp3"),
	&"cancel": preload("res://assets/キャンセル9.mp3"),
	&"pop": preload("res://assets/ピコッ.mp3"),
	&"cheer": preload("res://assets/女衆「おう！」.mp3"),
}

## 効果音ごとの音量(dB)。0 が元の音量、-6 でおよそ半分、+6 でおよそ2倍。ここを書き換えて調整する。
const VOLUMES_DB := {
	&"decide": 0.0,
	&"cancel": 6.0,
	&"pop": 0.0,
	&"cheer": 0.0,
}

## 効果音全体の音量(dB)。個別の値に加算される。
const MASTER_VOLUME_DB := 0.0

## 同時発音数。これを超えた分の再生要求は無視する(連打で音が割れないように)。
const MAX_VOICES := 8

var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	# ポーズ中や遷移中でも鳴らし切る
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in MAX_VOICES:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)

	# 決定音はどの画面のボタンでも共通なので、各シーンで繋がず生成時に自動で付ける
	get_tree().node_added.connect(_on_node_added)


func play(sound: StringName) -> void:
	if not SOUNDS.has(sound):
		push_error("Sfx: 未登録の効果音です name=%s" % sound)
		return
	for player in _players:
		if not player.playing:
			player.stream = SOUNDS[sound]
			# プレイヤーは使い回すので、鳴らすたびにその音の音量へ設定し直す
			player.volume_db = MASTER_VOLUME_DB + float(VOLUMES_DB.get(sound, 0.0))
			player.play()
			return


func _on_node_added(node: Node) -> void:
	var button := node as Button
	if button == null:
		return
	# 一度ツリーから外れて戻ってきたノードで二重接続にならないよう確認する
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	play(&"decide")
