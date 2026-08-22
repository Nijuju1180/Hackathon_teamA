extends CanvasLayer

## 制限時間(秒)。progress_barはこの時間の経過を表示するだけで、手動操作はできない。
@export_range(10.0, 600.0, 1.0) var time_limit_seconds: float = 100.0

# --- ノード参照 ---
# ノード名や階層が異なる場合は、シーンツリーからスクリプトへドラッグ＆ドロップしてパスを調整してください
@onready var comment_layer = $MainLayout/RootBox/PlayerArea/VideoScreen/SubViewport/commentLayer
@onready var comment_list: ItemList = $MainLayout/RootBox/SidePanel/VBoxContainer/CommentList
@onready var comment_input: LineEdit = $MainLayout/RootBox/SidePanel/VBoxContainer/CommentList/InputHBox/CommentInput
@onready var send_button: Button = $MainLayout/RootBox/SidePanel/VBoxContainer/CommentList/InputHBox/Button
@onready var progress_bar: Range = $MainLayout/RootBox/PlayerArea/ControlBar/ProgressBar
@onready var progress_marker: Control = $MainLayout/RootBox/PlayerArea/ControlBar/ProgressBar/Marker
@onready var result_overlay = $ResultOverlay

var _elapsed: float = 0.0
var _time_up: bool = false


func _ready() -> void:
	# 1. コメント生成シグナルの接続（流れたコメントを右側リストにも反映）
	if is_instance_valid(comment_layer):
		comment_layer.comment_spawned.connect(_on_comment_spawned)

	# 2. コメント送信ボタン・Enterキーの接続
	if is_instance_valid(send_button):
		send_button.pressed.connect(_on_send_pressed)
	if is_instance_valid(comment_input):
		comment_input.text_submitted.connect(_on_text_submitted)

	# 3. 制限時間バーの初期化
	if is_instance_valid(progress_bar):
		progress_bar.min_value = 0.0
		progress_bar.max_value = time_limit_seconds
		progress_bar.value = 0.0


func _process(delta: float) -> void:
	if _time_up:
		return
	_elapsed = minf(_elapsed + delta, time_limit_seconds)
	if is_instance_valid(progress_bar):
		progress_bar.value = _elapsed
		_update_marker()
	if _elapsed >= time_limit_seconds:
		_time_up = true
		if is_instance_valid(result_overlay):
			result_overlay.show_result()


## progress_barの現在値に合わせて、丸マーカーをバー上の対応位置に置く。
func _update_marker() -> void:
	if not is_instance_valid(progress_marker):
		return
	var ratio := 0.0
	if progress_bar.max_value > 0.0:
		ratio = progress_bar.value / progress_bar.max_value
	var x := progress_bar.size.x * ratio - progress_marker.size.x / 2.0
	var y := (progress_bar.size.y - progress_marker.size.y) / 2.0
	progress_marker.position = Vector2(x, y)


func _on_comment_spawned(comment: FlowingComment) -> void:
	if not is_instance_valid(comment_list):
		return
	
	# 右側リストにコメントを追加
	comment_list.add_item(comment.text)
	
	# リストが一定数を超えたら古いものを削除（パフォーマンス対策：最大50件）
	if comment_list.item_count > 50:
		comment_list.remove_item(0)
	
	# 常に最新（一番下）が見えるように自動スクロール
	comment_list.ensure_current_is_visible()


func _on_send_pressed() -> void:
	_submit_comment()


func _on_text_submitted(_new_text: String) -> void:
	_submit_comment()


func _submit_comment() -> void:
	if not is_instance_valid(comment_input) or not is_instance_valid(comment_layer):
		return
		
	var text: String = comment_input.text.strip_edges()
	if text.is_empty():
		return
	
	# 画面上にユーザー投稿コメントを流す
	comment_layer.push_comment(text, &"fan")
	
	# 入力欄をクリア
	comment_input.clear()
