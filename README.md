# ac-working-env

AI Coding Agent（主にClaude Code）が動作する開発作業環境を提供するVS Code Dev Containerです。

---

## 概要

このリポジトリは、AI Agentic Coding用途だけに限らず、一般的な開発作業を行うためのコンテナ環境を定義しています。

- **ベースOS:** Ubuntu 24.04 LTS
- **主なツール:** Claude Code、AWS CLI v2、mise（Node.js/Python バージョン管理）、yq
- **用途:** AI Coding AgentによるWebアプリケーション開発（フロントエンド・バックエンド）

---

## 前提条件

| ツール | 備考 |
|---|---|
| Docker Desktop / Docker Engine | コンテナ実行環境。WSL integration有効化必須。 |
| WSL2 (Ubuntu) | コンテナ内から `/var/run/docker.sock` を共有するために必要。 |
| Visual Studio Code | エディタ |
| [Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | VS Code拡張機能 |

また、以下をホストマシンに用意してください。コンテナ内からバインドマウントして共有します。
（詳細は docker-compose.yml を参照）

- `~/.gitconfig` — git設定ファイル
- `~/.ssh/` — SSH鍵（git over SSH等で使用）
- `~/.aws/` — AWS認証情報（AWS CLI / SDK で使用）
- `~/.claude/` — Claude Code設定ディレクトリ

---

## セットアップ手順

### 1. リポジトリの配置

本リポジトリは WSL2 (Ubuntu) 内の任意の場所に配置してください。

### 2. クレデンシャルファイルの作成

`.devcontainer/.credential.env.sample` をコピーして `.credential.env` を作成します。

```bash
cp .devcontainer/.credential.env.sample .devcontainer/.credential.env
```

`.devcontainer/.credential.env` をテキストエディタで開き、必要なクレデンシャルを設定してください。

> **Note:** `.credential.env` はgit管理対象外です（`.gitignore`で除外済み）。クレデンシャルをコミットしないよう注意してください。

### 3. Dev Containerの起動

VS Codeで WSL2 (Ubuntu) に接続して本リポジトリを開き、コマンドパレット（`Ctrl+Shift+P` / `Cmd+Shift+P`）から以下を実行します。

```
Dev Containers: Reopen in Container
```

初回起動時はDockerイメージのビルドが行われます。

### 4. 開発対象Gitリポジトリのclone
開発対象となるGitリポジトリは、コンテナ内の `/work/main` へ移動し `git clone` します。

---

## コンテナ環境の概要

### インストール済みツール

| ツール | 用途 |
|---|---|
| Claude Code | AI Coding Agent本体 |
| AWS CLI v2 | AWSリソースの操作 |
| AWS Session Manager Plugin | SSM経由のSSH接続 |
| mise | Node.js・Pythonのバージョン管理 |
| yq | YAML/JSON/TOMLの操作 |
| direnv | ディレクトリ単位の環境変数管理 |
| Docker CLI | コンテナ内からホストのDockerデーモンを操作 |

### ポート

| ポート | 用途 |
|---|---|
| `5173` | Vite dev server（フロントエンド） |
| `8000` | Backend API（FastAPI等） |
| `20022` | OpenSSH Server |

### ボリューム

| コンテナ内パス | 内容 |
|---|---|
| `/work/main` | 主作業領域（Dockerボリュームで永続化） |
| `/work/shared` | ホストの親ディレクトリをマウント |

---

## 詳細情報

内部構成・設定の詳細については [AGENTS.md](./AGENTS.md) を参照してください。
