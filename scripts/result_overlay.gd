extends ColorRect
## リザルト画面。show_result()で表示する。
## 評価内容の表示は未実装(健全度ゲージ側の実装待ち)。

@onready var _retry_button: Button = $ResultCenter/VBox/RetryButton
@onready var _title_button: Button = $ResultCenter/VBox/TitleButton


func _ready() -> void:
	visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	_title_button.pressed.connect(_on_title_pressed)


func show_result() -> void:
	visible = true


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_title_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
