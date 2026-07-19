# N01 1次元線形移流方程式

課題説明の正本は、公開教材の[N01 1次元線形移流方程式](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/N01.html)です。数式、実装手順、テスト、AI利用、完了条件は公開ページで確認してください。

## ローカルで編集するファイル

- 実装・実行: `exercises/N01_linear_advection/run.jl`
- 自分のテスト: `test/student/N01.jl`
- 学習ログ: `learning_logs/N01.md`

`run.jl`で実装するのは`rectangular_initial_condition`、`upwind_step!`、`centered_step!`の3関数です。

## 開始・実行・テスト

```bash
julia --project=. scripts/course.jl start N01
julia --project=. exercises/N01_linear_advection/run.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

## 公式出力

- `results/N01/upwind.png`
- `results/N01/centered-euler.png`
- `results/N01/summary.toml`

実装と確認が終わったら、公開ページの[完了条件](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/N01.html#完了条件)へ戻って照合してください。
