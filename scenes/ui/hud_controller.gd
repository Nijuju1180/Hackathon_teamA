extends CanvasLayer

# --- ノード参照 ---
# ノード名や階層が異なる場合は、シーンツリーからスクリプトへドラッグ＆ドロップしてパスを調整してください
@onready var comment_layer = $MainLayout/RootHBox/PlayerArea/VideoScreen/SubViewport/CommentLayer
@onready var comment_list: ItemList = $MainLayout/RootHBox/SidePanel/SideVBox/CommentList
@onready var comment_input: LineEdit = $MainLayout/RootHBox/SidePanel/SideVBox/InputHBox/CommentInput
@onready var send_button: Button = $MainLayout/RootHBox/SidePanel/SideVBox/InputHBox/SendButton
@onready var progress_bar: Range = $MainLayout/RootHBox/PlayerArea/ControlBar/ProgressBar # HSliderの場合は名前を合わせてください


func _ready() -> void:
	# 1. コメント生成シグナルの接続（流れたコメントを右側リストにも反映）
	if is_instance_valid(comment_layer):
		comment_layer.comment_spawned.connect(_on_comment_spawned)

	# 2. コメント送信ボタン・Enterキーの接続
	if is_instance_valid(send_button):
		send_button.pressed.connect(_on_send_pressed)
	if is_instance_valid(comment_input):
		comment_input.text_submitted.connect(_on_text_submitted)


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
