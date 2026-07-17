# F02 Juliaの配列・関数・テスト

詳しい説明は公開教材の
[F02 Juliaの配列・関数・テスト](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F02.html)
を参照してください。

## 編集対象

- `exercises/F02_julia_arrays_and_tests/run.jl`
- `test/student/F02.jl`
- `learning_logs/F02.md`

F01をmergeし、変更のないcleanな`main`へ戻った後、次のコマンドでF02を開始します。

```bash
julia --project=. scripts/course.jl start F02
```

## 実装と検証

1. `mean_temperature(values)`のTODOを実装します。
2. `temperature_anomaly(values)`のTODOを実装します。入力配列は変更せず、新しい配列を返します。
3. `test/student/F02.jl`のsmoke TODOを、自分で計算できる代表例へ変更します。
4. 次を実行します。

```bash
julia --project=. exercises/F02_julia_arrays_and_tests/run.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

公式出力：なし。`results/`へファイルは作りません。`learning_logs/templates/F02.md`を`learning_logs/F02.md`へコピーし、予想、変更、テスト、diff、判断を記録します。

## 完了条件

- 実数の配列とrangeで平均・偏差を計算できる。
- 空配列、`NaN`、`Inf`を理由が分かるエラーで拒否する。
- 偏差の平均がほぼ0で、入力配列を変更しない。
- 提供テストと`test/student/F02.jl`の代表例が通る。
- 公式出力がないことを確認し、学習ログ、commit、push、PR、Actions、diff、セルフレビュー、mergeを完了する。
