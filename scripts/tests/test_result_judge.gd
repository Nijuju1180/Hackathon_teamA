extends SceneTree
## ResultJudge.judge() のヘッドレステスト。
## 実行: godot4 --headless -s res://scripts/tests/test_result_judge.gd
## (プロジェクトの nix devShell 経由なら: nix develop -c godot4 --headless -s res://scripts/tests/test_result_judge.gd)
## 全件PASSなら "ALL TESTS PASSED" を出力し終了コード0、1件でもFAILなら終了コード1。

var _failures := 0


func _initialize() -> void:
	_check(
		"コメントを1つも消さない → no_action",
		ResultJudge.judge({}, {&"fan": 5, &"anti": 3}),
		"コメント無抵抗配信者"
	)
	_check(
		"出てきた分を全部消す → delete_all",
		ResultJudge.judge({&"fan": 3, &"anti": 2}, {}),
		"全消し系配信者"
	)
	_check(
		"アンチを狙い撃ち・ファンを温存",
		ResultJudge.judge(
			{&"anti": 8, &"fan": 1, &"tease": 1},
			{&"fan": 8, &"anti": 1, &"tease": 1}
		),
		"アンチを狩り、ファンを守る配信者"
	)
	_check(
		"削除/生存の構成比が全ジャンルで同じ → balanced",
		ResultJudge.judge(
			{&"fan": 5, &"tease": 5, &"anti": 5, &"neutral": 5},
			{&"fan": 5, &"tease": 5, &"anti": 5, &"neutral": 5}
		),
		"バランス系配信者"
	)
	_check(
		"targeted側のタイブレーク(anti > fan の優先順位)",
		ResultJudge.judge(
			{&"anti": 5, &"fan": 5},
			{&"tease": 5, &"neutral": 5}
		),
		"いじりには寛容、アンチには容赦なし配信者"
	)

	if _failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % _failures)
		quit(1)


func _check(label: String, result: Dictionary, expected_title: String) -> void:
	var actual: String = result.get("title", "")
	if actual == expected_title:
		print("[PASS] %s" % label)
	else:
		_failures += 1
		printerr("[FAIL] %s: expected '%s', got '%s'" % [label, expected_title, actual])
