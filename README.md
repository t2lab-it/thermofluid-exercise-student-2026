# 熱流体力学演習（2026）学生用リポジトリ

2026年度「熱流体力学演習」の個人課題用リポジトリです．
Juliaによる数値計算，テスト，Git／GitHub，学習ログ，AIエージェントを組み合わせて，結果を検証しながらコードを開発します．

<!-- contract-section: assigned_repository -->

## 必要な環境

- Julia 1.12.6
- Git
- VS Code
- GitHub Copilot，OpenAI Codex，Amazon Q Developerのいずれか一つ

詳しい導入手順は公開教材の[環境診断](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F00.html)を参照してください．

## 利用開始

GitHubのリポジトリ招待を受諾した後，割り当てられた自分の学生リポジトリをHTTPSで複製し，リポジトリのルートで依存関係を準備します．
詳しい導入手順は公開教材の[Git・GitHub・個人課題用リポジトリ](https://t2lab-it.github.io/thermofluid-exercise-2026/setup/git-github.html)を参照してください．

## 課題の進め方

課題開始方法には次の例外があります．

- `F00`: branch，commit，push，pull request，学習ログを作りません．
- `F01`: 課題branchを手動で作り，最初のpull requestを経験します．
- `F02`以降: 前課題をmergeして変更のない`main`へ戻った後，`course.jl start <ID>`で次の課題を開始します．
- `N05`・`N06`は提出単位`N05-N06`として1 branch，1 PR，1学習ログで完了します．
  - `F03`・`F04`と`N08`・`N09`も同様です．
  - 開始時は個別の内容IDではなく，`course.jl start F03-F04`のようなコマンドを使います．

通常課題の進め方は公開教材の[課題のbranch・PRワークフロー](https://t2lab-it.github.io/thermofluid-exercise-2026/guides/workflow.html)を参照してください．

## 主要コマンド

```bash
# F00の環境診断
julia --project=. scripts/course.jl preflight

# F02以降の課題開始例
julia --project=. scripts/course.jl start F02

# 現在課題と完了済み課題
julia --project=. scripts/course.jl status

# 公式生成物のサイズ制限
julia --project=. scripts/course.jl check-results

# 完了済み課題と現在課題のローカルテスト
julia --project=. -e 'using Pkg; Pkg.test()'
```

## リポジトリ構成

| パス                                   | 役割                                                        |
| -------------------------------------- | ----------------------------------------------------------- |
| `exercises/`                           | 課題ごとのスターターと公式`run.jl`                          |
| `test/provided/`                       | 教員が提供する公開テスト                                    |
| `test/student/`                        | 学生が課題ごとに追加するテスト                              |
| `learning_logs/`                       | 学習ログのテンプレートと記入済みログ                        |
| `results/`                             | 公式`run.jl`が生成する提出対象の結果                        |
| `scratch/`                             | 一時的な試行．正式な成果物は置かない                        |
| `scripts/`                             | 課題進行と生成物検査の補助コマンド                          |
| `src/`                                 | 後半課題で共通化するJuliaコード                             |
| [`FINAL_PROJECT.md`](FINAL_PROJECT.md) | N09までの必要なコードを別のプロジェクトリポジトリへ移す手順 |

## 現在の収録範囲

| 課題ID | 内容                                              |
| ------ | ------------------------------------------------- |
| `F00`  | 環境診断                                          |
| `F01`  | 最初のpull request                                |
| `F02`  | Juliaの配列・関数・テスト                         |
| `F03`  | ベクトル解析の公式，解析微分（提出単位`F03-F04`） |
| `F04`  | 数値微分と格子収束（提出単位`F03-F04`）           |
| `N01`  | 1次元線形移流方程式                               |
| `N07`  | 二次元拡散・移流拡散                              |
| `N08`  | PDE分類・Laplace方程式                            |
| `N09`  | Poisson方程式                                     |

`N02`以降の数値課題は順次追加します．
