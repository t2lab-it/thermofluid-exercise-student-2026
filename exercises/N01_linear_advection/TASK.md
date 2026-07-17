# N01 1次元線形移流方程式

詳しい説明は公開教材の
[N01 1次元線形移流方程式](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/N01.html)
を参照してください。

## 編集対象

- `exercises/N01_linear_advection/run.jl`
- `test/student/N01.jl`
- `learning_logs/N01.md`

F03をmergeしてcleanな`main`へ戻った後、次で開始します。

```bash
julia --project=. scripts/course.jl start N01
```

## 実験の契約

自己完結（self-contained）した`run.jl`を上から読み、初期条件、境界条件、時間発展、出力までの流れを一つのファイルで追います。N01では`src/`をimportしません。

- 領域は`0 <= x <= 2`、初期値は背景1、`0.5 <= x <= 1.0`で2です。
- 左端は値1を固定し、右端は隣接点と同じ値にするゼロ勾配境界です。
- 移流速度は正とし、二つの配列を交互に使って時間発展します。
- upwind + Eulerは`cfl <= 1`で安定な比較例です。
- centered + Eulerは振動・overshoot・undershootを観察するための意図的な不安定比較です。
- 最終ステップの`dt`を調整し、ちょうど`t_final`に到達します。記録するCFLは調整後の実効値です。

`rectangular_initial_condition`と二つの`step!`関数に残したTODOだけを実装してください。upwind（風上差分）では後退差分、centeredでは中心差分を使います。意図的に不安定なcentered法を安定化してはいけません。

## 実行と検証

```bash
julia --project=. exercises/N01_linear_advection/run.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

公式出力は次の3ファイルです。

- `results/N01/upwind.png`
- `results/N01/centered-euler.png`
- `results/N01/summary.toml`

`test/student/N01.jl`のsmoke TODOを、手計算できる更新式または安定・不安定比較の代表的な数値特性へ変更してください。テンプレートを`learning_logs/N01.md`へコピーし、予想、実効CFL、最小値・最大値、図から分かったことを記録します。

## AI利用と情報管理

N01でAIを使う場合は、式の説明や自分のコードのデバッグ補助に限定し、完成コード全体の生成を依頼しません。利用内容と採否を学習ログへ記録してください。氏名、学籍番号、トークン、秘密鍵、未公開URLなどの個人情報・秘密情報を入力しないでください。

## 完了条件

- 初期矩形波とupwind・centeredの更新式をコードと手計算で対応づけた。
- upwindが範囲内に保たれ、centered + Eulerで不安定性が現れることを数値と図で確認した。
- 実効CFLと最終時刻、3つの公式出力を確認した。
- 提供テストと自分の代表テストが通る。
- 学習ログ、commit、push、PR、Actions、diff、セルフレビュー、mergeを確認した。
