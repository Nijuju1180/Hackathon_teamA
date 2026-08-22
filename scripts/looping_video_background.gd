extends VideoStreamPlayer
## 背景動画をループ再生する。VideoStreamPlayer自体にloopプロパティが無いため、
## 再生終了時に再度playする。

func _ready() -> void:
	finished.connect(play)
