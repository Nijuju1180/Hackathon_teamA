extends ColorRect
## リザルト画面。show_result(deleted_counts, survived_counts) で表示する。
## 判定ロジック本体は ResultJudge (scripts/result_judge.gd) にある。

@onready var _retry_button: Button = $ResultCenter/VBox/RetryButton
@onready var _title_button: Button = $ResultCenter/VBox/TitleButton
@onready var _judge_title: Label = $ResultCenter/VBox/ResultJudgeTitle
@onready var _judge_sub: Label = $ResultCenter/VBox/ResultSub


func _ready() -> void:
	visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	_title_button.pressed.connect(_on_title_pressed)


func show_result(deleted_counts: Dictionary, survived_counts: Dictionary) -> void:
	visible = true
	var judgement := ResultJudge.judge(deleted_counts, survived_counts)
	_judge_title.text = judgement.title
	_judge_sub.text = judgement.description


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
