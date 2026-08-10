# 最終プロジェクトへのcode移行

最終プロジェクトは、個人projectでもペアprojectでも、このstudent repositoryとは別のproject repositoryで行います。`thermofluid-project-base-2026`から作られた別のproject repositoryが、計画、実装、test、結果、発表資料の正本です。

このstudent repositoryはN09までのcourseworkの正本です。個人projectでも提出先にはせず、projectの発表資料や最終成果物は置きません。

## 移すものを絞る

course repository全体を複製しません。projectの問いに必要なものだけを選びます。

- `src/`のうち、利用するsolver・離散化・診断に必要なfile。
- そのcodeの正しさを守る`test/student/`または対応する局所test。
- 実行に必要な小さな設定、入力、environment情報。
- 出典、license、元の課題、source commitを説明する記録。

`learning_logs/`、全課題の`exercises/`、不要な`results/`、course進行scriptをまとめてコピーしません。大容量dataやmachine固有outputも移しません。

## 移行前に元を確定する

student repository側をcleanにし、利用するcodeのtestを実行してからsource commitを記録します。

```bash
git status --short
git rev-parse HEAD
julia --project=. -e 'using Pkg; Pkg.test()'
```

公開されている参照元ならrepository URLとsource commitを記録します。参照元がprivateの場合は、公開してよいsource commitだけをproject repositoryに記録し、private repositoryのURL、氏名、学籍番号、秘密情報は転記しません。

## project repositoryへ移す

移行先のissueまたはPull Requestへ、次を記録します。

- **参照元**: 元課題ID、公開可能なrepository URL、source commit、利用したfile。
- **変更点**: projectの問いに合わせて変えた境界条件、API、data構造、設定、診断。
- **追加した検証**: project固有の解析解、benchmark、保存則、residual、格子・時間刻み確認、CPU smoke test。
- **出典とlicense**: course asset、外部package・data、他学生の成果、AI提案の由来と利用条件。

copy後は移行先で新しいbranchを作り、必要なfileだけを追加します。historyを丸ごと移す必要はありませんが、上記の参照情報から元の状態を追跡できるようにします。

## 正しさを再確認する

元課題のtestが通っていたことだけに依存しません。project repositoryの環境・境界・入力・比較条件に対してtestを追加します。

1. 移行直後に元と同等の縮小caseを実行し、場、保存量、residual等を比較する。
2. projectで変更した部分を失敗させる局所testを追加する。
3. 小さなCPU smoke testを、第三者が再実行できるcommandにする。
4. GPU・長時間計算は同じcode pathの縮小caseと、本番環境・commit・入力・代表時間を分けて記録する。

## 出典と共同作業

自分が書いたcourseworkでも、source commitと変更点を残します。他学生の成果を利用する場合は、本人の許可、author、参照元、license、担当範囲を明記します。公開してよい条件が確認できないcodeは移しません。

Coding Agentや生成AIの重要な提案を利用した場合は、提案内容と採用・修正・却下の判断をPull Requestへ記録します。出典記録はcode量や文章量を増やすためではなく、判断と再現性を説明するために使います。

## 移行後の境界

- student repositoryはN09までのcourseworkを保ち、projectのbranchや発表資料を混在させません。
- project repositoryはissue、feature branch、Pull Request、author以外のreviewを使います。
- 個人projectでは別projectの学生、教員、またはTAを第三者reviewer・再実行者にします。
- public projectを原則とし、private例外でも同じtemplate、CI、rubric、支援、第三者reviewを使います。
- 実roster、個別相談、成績、口頭確認、token、credentialはpublic repositoryへ置きません。

## 移行checklist

- [ ] 別のproject repositoryを移行先にした。
- [ ] 必要なcode、test、設定だけを選んだ。
- [ ] source commitと公開可能な参照元を記録した。
- [ ] 変更点と追加した検証を記録した。
- [ ] project固有の局所testとCPU smoke testを実行した。
- [ ] license、他学生の成果、AI提案の出典を確認した。
- [ ] private情報と大容量dataを含めていない。
- [ ] student repositoryに発表資料・最終成果物を置いていない。
