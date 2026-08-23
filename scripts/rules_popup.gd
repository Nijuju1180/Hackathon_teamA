extends Control
## ルール説明ポップアップ。戻る/すすむでページ送りし、最終ページの「すすむ」は「とじる」になる。
## ページ数は pages 配列の要素数で決まる(後から増減しても自動対応)。

signal closed

## 開閉時のフェード秒数
const FADE_SECONDS := 0.25

@export var pages: Array[String] = [
	"画面に流れてくるコメントを、制限時間内にクリックして消していこう。",
	"消したコメントのジャンルによって、チャンネルの評価が変わるよ。",
	"時間切れになったら結果発表。どんなチャンネルになったか見てみよう。",
]

@onready var _page_indicator: Label = $PanelCenter/Panel/Margin/VBox/PageIndicator
@onready var _page_text: Label = $PanelCenter/Panel/Margin/VBox/PageText
@onready var _back_button: Button = $PanelCenter/Panel/Margin/VBox/ButtonRow/BackButton
@onready var _next_button: Button = $PanelCenter/Panel/Margin/VBox/ButtonRow/NextButton

var _page_index: int = 0
var _closing: bool = false


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_update_page()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, FADE_SECONDS)


func _on_back_pressed() -> void:
	if _closing or _page_index <= 0:
		return
	_page_index -= 1
	_update_page()


func _on_next_pressed() -> void:
	if _closing:
		return
	if _page_index >= pages.size() - 1:
		_close()
		return
	_page_index += 1
	_update_page()


func _close() -> void:
	_closing = true
	# フェードアウト中の再クリックを防ぐ
	_back_button.disabled = true
	_next_button.disabled = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	await tween.finished
	closed.emit()
	queue_free()


func _update_page() -> void:
	_page_text.text = pages[_page_index]
	_page_indicator.text = "%d / %d" % [_page_index + 1, pages.size()]
	_back_button.disabled = _page_index == 0
	_next_button.text = "とじる" if _page_index == pages.size() - 1 else "すすむ"
