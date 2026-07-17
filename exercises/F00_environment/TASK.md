# F00 環境診断

詳しい説明と画面例は、公開教材の
[F00 環境診断](https://t2lab-it.github.io/thermofluid-exercise-2026/assignments/F00.html)
を参照してください。このファイルには、リポジトリ内で実行する手順だけをまとめます。

## 完了すること

- Julia 1.12.6、Git、VS CodeとJulia拡張`julialang.language-julia`がローカルで起動できる。
- 自分のGitHubアカウントで課題リポジトリを開ける。
- 正式対応Agentのうち、GitHub Copilot、OpenAI Codex、Amazon Q Developerのいずれか一つで、ファイル編集とローカルコマンド実行を確認する。

F00ではファイルを編集せず、branch、commit、push、PR、学習ログを作りません。

## 1. Juliaを固定する

Juliaupをインストールした後、このリポジトリのrootで次を実行します。

```bash
juliaup add 1.12.6
juliaup override set 1.12.6
julia --version
```

最後の出力が`julia version 1.12.6`と完全に一致することを確認してください。

## 2. リポジトリを準備する

GitHub Classroomに表示された自分のclone URLを使います。

```bash
git clone <自分の課題リポジトリURL>
cd <cloneされたディレクトリ>
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Windows、macOS、Linuxのいずれでも、以降のコマンドはリポジトリrootで実行します。
VS CodeのExtensions画面でJulia拡張（ID: `julialang.language-julia`）をインストールし、VS Codeを再起動してください。

## 3. 機械診断を読む

```bash
julia --project=. scripts/course.jl preflight
```

この実行はJulia、Git、VS Code、Julia拡張を観測して表示するだけで、進捗を変更しません。`NEEDS SETUP`があれば、直後の`Action`を実施してから再実行してください。次のテストも実行します。

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## 4. 手動確認を付けて完了する

GitHubへサインインして課題リポジトリを開けることを確認します。次に、正式対応Agentを一つだけ選び、VS Code内またはCodex CLIでファイル編集と安全なローカルコマンド実行を確認します。Copilotが利用できない場合はCodexまたはAmazon Qへ切り替えて構いません。

選んだ製品名に応じて、次のいずれか一つを実行します。

```bash
julia --project=. scripts/course.jl preflight --confirm-github --confirm-agent copilot
julia --project=. scripts/course.jl preflight --confirm-github --confirm-agent codex
julia --project=. scripts/course.jl preflight --confirm-github --confirm-agent amazon-q
```

成功すると`F00 is complete`と`Current exercise is now F01`が表示されます。公式生成物はありません。

## 秘密情報とプライバシー

アクセストークン、パスワード、秘密鍵、個人情報を、Agentへの依頼、terminal出力、スクリーンショット、リポジトリへ貼り付けないでください。誤って表示した場合はcommitせず、教員またはTAへ相談してください。

## 完了条件

- 機械観測3項目がすべて`PASS`である。
- GitHubと正式対応Agent一つを明示的に確認した。
- `course_progress.toml`が`completed = ["F00"]`、`current = "F01"`になった。
- F00用のbranch、PR、学習ログを作っていない。
