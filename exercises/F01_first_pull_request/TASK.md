# F01 最初のPull Request

詳しい説明は公開教材の
[F01 最初のPull Request](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F01.html)
を参照してください。

## 編集対象

- `exercises/F01_first_pull_request/run.jl`
- `test/student/F01.jl`
- `learning_logs/F01.md`

この課題ではbranch作成を手動で経験します。`scripts/course.jl start F02`を使うのはF01をmergeした後です。F01ではAgentの利用を説明、エラー解説、練習問題に限り、TODOの答えそのものは自分で書きます。

## 手順

1. `main`にいることと、F00完了後の変更を確認してから、手動で課題branchを作ります。

   ```bash
   git branch --show-current
   git status --short
   git diff -- course_progress.toml
   ```

   F00からF01へ進んだときは、`course_progress.toml`だけが変更済みと表示されるのが正常です。F00はGit commitを行わない課題なので、この進捗変更はF01で初めてcommitします。ほかの変更がある場合はbranchを作らず、教員・TAへ相談してください。

   ```bash
   git switch -c exercise/F01-first-pull-request
   ```

2. `run.jl`の`student_greeting`にあるTODOを実装します。前後の空白を除いた名前`name`に対し、`Hello, name!`という`String`を返してください。空白だけの名前を拒否する処理は変更しません。次に、`test/student/F01.jl`のsmoke TODOを、自分で選んだ名前を使う代表的な挨拶のテストへ置き換えます。

3. ローカルで実行し、テストします。

   ```bash
   julia --project=. exercises/F01_first_pull_request/run.jl "自分の名前"
   julia --project=. -e 'using Pkg; Pkg.test()'
   ```

4. 公式出力：なし。F01では`results/`へファイルを生成しません。

5. `learning_logs/templates/F01.md`を`learning_logs/F01.md`へコピーし、実行前予想、作業、diff、テスト結果、判断を記入します。

6. 変更範囲を確認してcommitします。

   ```bash
   git status --short
   git diff
   git add course_progress.toml exercises/F01_first_pull_request/run.jl test/student/F01.jl learning_logs/F01.md
   git commit -m "feat: complete F01 first pull request"
   ```

7. 課題branchを手動で公開します。

   ```bash
   git push -u origin exercise/F01-first-pull-request
   ```

8. GitHubで`exercise/F01-first-pull-request`から`main`へのPull Requestを作ります。

9. Actionsが成功したことを確認します。失敗した場合はログを読み、同じbranchへ修正を追加します。

10. Pull RequestのFiles changedでdiffを確認し、意図しないファイルや秘密情報がないことを確認します。

11. 完了条件を使ってセルフレビューし、必要な修正を同じPull Requestへ追加します。

12. Pull Requestをmergeします。merge後は`main`へ戻り、手動で最新状態を取得します。

   ```bash
   git switch main
   git pull --ff-only
   ```

## 完了条件

- `student_greeting`が提供テストと自分の確認例を通る。
- `test/student/F01.jl`を代表例へ変更し、そのテストが通る。
- 公式出力がないことを確認した。
- `learning_logs/F01.md`を記入した。
- 指定branch、1件のPull Request、Actions、diff、セルフレビュー、mergeを順に経験した。
- F01の作業を`main`へ直接pushしていない。
