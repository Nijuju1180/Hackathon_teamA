extends ColorRect
## リザルト画面。show_result(deleted_counts, survived_counts) で表示する。
## 判定ロジック本体は ResultJudge (scripts/result_judge.gd) にある。

## 時間切れ直後にいきなり出さず、この秒数かけてフェードインする
const FADE_IN_SECONDS := 0.6
## 「リザルト」→評価タイトル→評価コメント→ボタンを1段ずつ出すときの1段あたりのフェード時間
const STEP_FADE_SECONDS := 0.4
## 前の段が出てから次の段が出るまでの待ち時間
const STEP_DELAY_SECONDS := 0.5

@onready var _result_title: Label = $ResultCenter/VBox/ResultTitle
@onready var _judge_title: Label = $ResultCenter/VBox/ResultJudgeTitle
@onready var _judge_sub: Label = $ResultCenter/VBox/ResultSub
@onready var _button_box: VBoxContainer = $ResultCenter/VBox/ButtonBox
@onready var _retry_button: Button = $ResultCenter/VBox/ButtonBox/RetryButton
@onready var _title_button: Button = $ResultCenter/VBox/ButtonBox/TitleButton


func _ready() -> void:
	visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	_title_button.pressed.connect(_on_title_pressed)


func show_result(deleted_counts: Dictionary, survived_counts: Dictionary) -> void:
	var judgement := ResultJudge.judge(deleted_counts, survived_counts)
	_judge_title.text = judgement.title
	_judge_sub.text = judgement.description

	# 出現前も VBox 内の場所は確保させ、段が増えても既出の段が動かないようにする
	for step in _steps():
		step[0].modulate.a = 0.0
	_set_buttons_enabled(false)

	modulate.a = 0.0
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN_SECONDS)
	for step in _steps():
		var node: CanvasItem = step[0]
		var sound: StringName = step[1]
		tween.tween_interval(STEP_DELAY_SECONDS)
		if sound != &"":
			tween.tween_callback(Sfx.play.bind(sound))
		tween.tween_property(node, "modulate:a", 1.0, STEP_FADE_SECONDS)
	tween.tween_callback(_set_buttons_enabled.bind(true))


## 表示する順番そのもの。[表示する段, 出現に合わせて鳴らす効果音] の並び。
## 効果音が空の段は無音(ボタンは押したときに決定音が鳴る)。
func _steps() -> Array[Array]:
	var steps: Array[Array] = [
		[_result_title, &"pop"],
		[_judge_title, &"pop"],
		[_judge_sub, &"cheer"],
		[_button_box, &""],
	]
	return steps


## 透明なうちに押せてしまわないようにする
func _set_buttons_enabled(enabled: bool) -> void:
	_retry_button.disabled = not enabled
	_title_button.disabled = not enabled


func _on_retry_pressed() -> void:
	SceneTransition.reload_scene()


func _on_title_pressed() -> void:
	SceneTransition.change_scene("res://scenes/title.tscn")
