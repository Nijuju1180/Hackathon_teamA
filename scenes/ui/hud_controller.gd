extends CanvasLayer

## 制限時間(秒)。progress_barはこの時間の経過を表示するだけで、手動操作はできない。
@export_range(10.0, 600.0, 1.0) var time_limit_seconds: float = 100.0
## 配信ヘッダーに表示する視聴者数の初期値・変動幅
@export var viewer_count_base: int = 128
@export_range(0.2, 5.0, 0.1) var viewer_count_update_seconds: float = 1.5

# --- ノード参照 ---
# ノード名や階層が異なる場合は、シーンツリーからスクリプトへドラッグ＆ドロップしてパスを調整してください
@onready var comment_layer = $MainLayout/RootBox/PlayerArea/VideoWrapper/VideoScreen/SubViewport/commentLayer
@onready var comment_list: ItemList = $MainLayout/RootBox/SidePanel/VBoxContainer/CommentList
@onready var comment_input: LineEdit = $MainLayout/RootBox/SidePanel/VBoxContainer/InputHBox/CommentInput
@onready var send_button: Button = $MainLayout/RootBox/SidePanel/VBoxContainer/InputHBox/Button
@onready var progress_bar: Range = $MainLayout/RootBox/PlayerArea/ControlBar/ControlRow/ProgressBar
@onready var progress_marker: Control = $MainLayout/RootBox/PlayerArea/ControlBar/ControlRow/ProgressBar/Marker
@onready var result_overlay = $ResultOverlay
@onready var viewer_count_label: Label = $MainLayout/RootBox/PlayerArea/VideoWrapper/StreamHeader/HeaderRow/ViewerRow/ViewerCountLabel
@onready var elapsed_label: Label = $MainLayout/RootBox/PlayerArea/VideoWrapper/StreamHeader/HeaderRow/ElapsedLabel
@onready var live_dot: Control = $MainLayout/RootBox/PlayerArea/VideoWrapper/StreamHeader/HeaderRow/LiveBadge/LiveBadgeRow/LiveDot
@onready var like_button: Button = $MainLayout/RootBox/PlayerArea/ControlBar/ControlRow/LikeButton
@onready var reaction_layer = $MainLayout/RootBox/PlayerArea/VideoWrapper/ReactionLayer

var _elapsed: float = 0.0
var _time_up: bool = false
var _viewer_count: int
var _viewer_count_accum: float = 0.0


func _ready() -> void:
	# 1. コメント生成シグナルの接続（流れたコメントを右側リストにも反映）
	if is_instance_valid(comment_layer):
		comment_layer.comment_spawned.connect(_on_comment_spawned)
		comment_layer.comment_dismissed.connect(_on_comment_dismissed)

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

	# 4. 配信ヘッダー（視聴者数・LIVEバッジ点滅）の初期化
	_viewer_count = viewer_count_base
	_update_viewer_count_label()
	_start_live_dot_blink()

	# 5. いいねボタンの接続
	if is_instance_valid(like_button):
		like_button.pressed.connect(_on_like_pressed)


func _process(delta: float) -> void:
	if _time_up:
		return
	_elapsed = minf(_elapsed + delta, time_limit_seconds)
	if is_instance_valid(progress_bar):
		progress_bar.value = _elapsed
		_update_marker()
	if is_instance_valid(elapsed_label):
		elapsed_label.text = _format_time(_elapsed)

	_viewer_count_accum += delta
	if _viewer_count_accum >= viewer_count_update_seconds:
		_viewer_count_accum = 0.0
		_viewer_count = maxi(1, _viewer_count + randi_range(-3, 5))
		_update_viewer_count_label()

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


func _update_viewer_count_label() -> void:
	if is_instance_valid(viewer_count_label):
		viewer_count_label.text = "%d人視聴中" % _viewer_count


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]


## LIVEバッジの丸を明滅させ続ける
func _start_live_dot_blink() -> void:
	if not is_instance_valid(live_dot):
		return
	var tween := create_tween().set_loops()
	tween.tween_property(live_dot, "modulate:a", 0.25, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(live_dot, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)


func _on_like_pressed() -> void:
	if is_instance_valid(reaction_layer):
		reaction_layer.spawn_heart()


func _on_comment_spawned(comment: FlowingComment) -> void:
	if not is_instance_valid(comment_list):
		return

	# 右側リストにコメントを追加（削除検知用にコメント本体をメタデータとして紐付ける）
	var idx := comment_list.add_item(comment.text)
	comment_list.set_item_metadata(idx, comment)

	# リストが一定数を超えたら古いものを削除（パフォーマンス対策：最大50件）
	if comment_list.item_count > 50:
		comment_list.remove_item(0)

	# 常に最新（一番下）が見えるように自動スクロール
	comment_list.ensure_current_is_visible()


## 画面上でクリックされて消されたコメントを、右側リスト上で削除済み表示に切り替える
func _on_comment_dismissed(comment: FlowingComment) -> void:
	if not is_instance_valid(comment_list):
		return
	for i in comment_list.item_count:
		if comment_list.get_item_metadata(i) == comment:
			comment_list.set_item_text(i, "このコメントは削除されました")
			comment_list.set_item_custom_fg_color(i, Color(1.0, 0.3, 0.3))
			return


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
