# F03 数値計算の準備

詳しい説明は公開教材の
[F03 数値計算の準備](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F03.html)
を参照してください。

## 編集対象

- `exercises/F03_numerical_primer/run.jl`
- `test/student/F03.jl`
- `learning_logs/F03.md`

F02をmergeしてcleanな`main`へ戻った後、次で開始します。

```bash
julia --project=. scripts/course.jl start F03
```

## 数式・添字・コード

Juliaの`u[i]`を格子座標 $x_i$ における値 $u_i$ に対応させます。後退差分は
`(u[i] - u[i - 1]) / dx`、中心差分は
`(u[i + 1] - u[i - 1]) / (2 * dx)`です。中心差分では左右の点が必要なので、端点の添字は使えません。

1. `uniform_grid`を、両端を含む等間隔な`n`点として実装します。
2. 二つの差分TODOを上の式に対応させます。
3. `test/student/F03.jl`のsmoke TODOを、手計算できる一次関数の代表例へ変更します。
4. 実行とテストを行います。

```bash
julia --project=. exercises/F03_numerical_primer/run.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

公式出力：なし。`results/`へファイルは作りません。`learning_logs/templates/F03.md`を`learning_logs/F03.md`へコピーし、座標・添字・式・コード・テストの対応を記録します。

F03の関数はこの課題ファイル内だけで使います。`src/`へ切り出さず、後続のN01もこのファイルをimportしません。

## 完了条件

- 格子の点数、両端、間隔が正しい。
- 手計算例と一次関数で二つの差分を確認した。
- 不正な点数、端点、`dx`、添字、非有限値を拒否する。
- 提供テストと`test/student/F03.jl`が通る。
- 公式出力なし、学習ログ、commit、push、PR、Actions、diff、セルフレビュー、mergeを確認した。
