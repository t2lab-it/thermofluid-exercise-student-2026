# 熱流体力学演習（2026）学生用リポジトリ

数式・実装・テストを対応させ、数値結果と限界を説明するための個人課題リポジトリです。

<!-- contract-section: assigned_repository -->
## 初回の準備

- Julia 1.12.7
- Git
- VS Code
- GitHub Copilot、OpenAI Codex、Amazon Q Developerのいずれか一つ

招待を受諾し、割り当てられた自分の学生リポジトリを複製します。
[環境診断](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F00.html)と
[Git・GitHubの準備](https://t2lab-it.github.io/thermofluid-exercise-2026/setup/git-github.html)に沿って進めてください。

```fish
julia --project=. scripts/course.jl preflight
```

## 課題を開く

[公開課題ページ](https://t2lab-it.github.io/thermofluid-exercise-2026/)から、対応するローカルの課題フォルダを開きます。
通常編集するのは `run.jl`（実装）、`tests.jl`（自分の確認）、`learning_log.md`（記録）です。
同じ場所の `provided_tests.jl` で教員提供の数値・入出力テストを読めます。

| 提出単位 | フォルダ | 内容 |
|---|---|---|
| F00 | `exercises/F00_environment/` | 環境診断 |
| F01 | `exercises/F01_first_pull_request/` | 最初のPR |
| F02 | `exercises/F02_julia_arrays_and_tests/` | 配列・関数・テスト |
| F03-F04 | `exercises/F03-F04_vector_calculus/` | ベクトル解析・数値微分 |
| N01 | `exercises/N01_linear_advection/` | 一次元線形移流 |

```fish
julia --project=. scripts/course.jl status
```

F01の手動branch作成、F02以降の課題開始、提出順は[課題ワークフロー](https://t2lab-it.github.io/thermofluid-exercise-2026/guides/workflow.html)を参照してください。
N02以降は順次追加します。必要な教材が揃うまでは `start` がbranchと進捗を変更せず終了します。

## 実行とテスト

リポジトリのルートで、課題ページに記載された `run.jl` を実行します。

```fish
julia --project=. -e 'using Pkg; Pkg.test()'
```

現在・完了済みの課題を検証します。開始した課題の未実装や未記入の自作テストは失敗します。
結果がある課題では、実行時に課題内の `results/` が作られます。図・数値を確認し、ログから参照してcommitします。

詳しい[コマンド一覧](https://t2lab-it.github.io/thermofluid-exercise-2026/guides/commands.html)と
[最終プロジェクトへの移行](https://t2lab-it.github.io/thermofluid-exercise-2026/guides/final-project-handoff.html)も参照してください。
