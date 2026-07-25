# 熱流体力学演習（2026）学生用リポジトリ

2026年度「熱流体力学演習」で使用する、個人GitHub Classroom assignmentの学生用private template repositoryです。Juliaによる数値計算を題材に、テスト、Git／GitHub、学習ログ、Coding Agentを組み合わせて、結果を検証しながらコードを開発します。

## はじめに

課題に取り組むときは、次の3つを使い分けてください。

- [公開教材サイト](https://t2lab-it.github.io/thermofluid-exercise-2026/): 数式、背景、詳しい課題説明の正本
- このREADME: リポジトリ全体の使い方と共通ワークフロー
- `exercises/<課題>/run.jl`: 公開教材の課題ページで指定された実装・実行対象

## 必要な環境

- Julia 1.12.6
- Git
- VS CodeとJulia拡張`julialang.language-julia`（必須）
- Japanese Language Pack（任意）
- GitHub Copilot、OpenAI Codex、Amazon Q Developerのいずれか一つ

Windows、macOS、Linuxのローカル環境を対象にします。詳しい導入手順は公開教材の[F00 環境診断](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F00.html)を参照してください。

## 利用開始

GitHub Classroomで作成された自分の課題リポジトリをcloneし、リポジトリrootで依存関係を準備します。

```bash
git clone <自分の課題リポジトリURL>
cd <cloneされたディレクトリ>
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. scripts/course.jl preflight
```

最後の`preflight`は環境を観測して表示するだけで、確認引数を付けない限り進捗を変更しません。表示された`NEEDS SETUP`と`Action`を読み、F00の手順に沿って環境を整えてください。

## 課題の進め方

課題開始方法には次の例外があります。

- `F00`: branch、commit、push、Pull Request、学習ログを作りません。
- `F01`: 課題branchを手動で作り、最初のPull Requestを経験します。
- `F02`以降: 前課題をmergeしてcleanな`main`へ戻った後、`course.jl start <ID>`で次の課題を開始します。

通常課題は次の順で進めます。

1. 公開教材の対応する課題ページを読み、指定された`run.jl`を確認する。
2. 課題branchで実装し、自分のテストを追加する。
3. ローカルテストを実行し、必要な公式出力を再生成する。
4. 学習ログに予想、変更、diff、テスト、数値結果、判断を記録する。
5. 変更をcommitしてpushし、`main`へのPull Requestを作る。
6. Actions、Files changed、完了条件を確認してセルフレビューする。
7. Pull Requestをmergeし、ローカルの`main`を更新する。

Pull Requestを作る前に、次の順で整形、diff確認、テストを実行します。

```bash
julia --project=. scripts/format.jl
git diff
julia --project=. -e 'using Pkg; Pkg.test()'
```

整形後の`git diff`を読み、意図しない変更がないことを確認してからcommitしてください。CIは整形状態を検査しますが、ファイルの編集やpushは行いません。

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

# 学生が編集するJuliaコードを自動整形
julia --project=. scripts/format.jl

# CIと同じ整形状態の検査
julia --project=. scripts/format.jl --check

# 完了済み課題と現在課題のローカルテスト
julia --project=. -e 'using Pkg; Pkg.test()'
```

`start`はcleanな`main`、課題の順序、現在までのローカルテスト、生成物サイズを確認してから課題branchを作ります。pull、push、Pull Request、mergeは自動化しません。

## リポジトリ構成

| パス | 役割 |
|---|---|
| `exercises/` | 課題ごとのスターターと公式`run.jl` |
| `test/provided/` | 教員が提供する公開テスト |
| `test/student/` | 学生が課題ごとに追加するテスト |
| `learning_logs/` | 学習ログのテンプレートと記入済みログ |
| `results/` | 公式`run.jl`が生成する提出対象の結果 |
| `scratch/` | 一時的な試行。正式な成果物は置かない |
| `scripts/` | 課題進行と生成物検査の補助コマンド |
| `src/` | 後半課題で共通化するJuliaコード |

## 現在の収録範囲

| 課題ID | 内容 |
|---|---|
| `F00` | 環境診断 |
| `F01` | 最初のPull Request |
| `F02` | Juliaの配列・関数・テスト |
| `F03` | ベクトル解析の公式、解析微分、自動微分 |
| `F04` | 数値微分と格子収束 |
| `N01` | 1次元線形移流方程式 |
| `N07` | 二次元拡散・移流拡散 |
| `N08` | PDE分類・Laplace方程式 |
| `N09` | Poisson方程式 |

`N02`以降の数値課題は順次追加します。

## 注意事項

- アクセストークン、パスワード、秘密鍵、不要な個人情報をcommitしないでください。
- `test/provided/`の提供テストを削除したり、判定を弱めたりしないでください。
- 公式`run.jl`が`results/<課題ID>/`へ生成した成果物は、サイズ制限を確認してcommitします。
- `scratch/`は一時作業用です。提出対象の実装や結果の正本にしません。
- Coding Agentの提案は、diff、テスト、数値結果を自分で確認し、採用・修正・却下の理由を学習ログへ記録してください。
