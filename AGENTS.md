# AGENTS.md — ac-working-env リポジトリ仕様

このファイルは、本リポジトリで作業するAI Coding Agentが環境の全体像・制約・規則を把握するためのリファレンスです。

---

## 1. リポジトリの目的

AI Coding Agent（主にClaude Code）が動作する開発作業環境を提供するVS Code Dev Containerの定義リポジトリです。

---

## 2. ディレクトリ・ファイル構成

```
ac-working-env/
├── README.md
├── AGENTS.md                              # 本ファイル
└── .devcontainer/
    ├── devcontainer.json                  # VS Code Dev Container設定
    ├── docker-compose.yml                 # コンテナ定義
    ├── Dockerfile                         # コンテナイメージ定義（Ubuntu 24.04ベース）
    ├── postCreateCommand.sh               # コンテナ初回作成時の初期化スクリプト
    ├── postStartCommand.sh                # コンテナ起動時のスクリプト
    ├── .env                               # 非クレデンシャルの環境変数（git管理対象）
    ├── .credential.env.sample             # クレデンシャル変数のサンプル（git管理対象）
    ├── .credential.env                    # 実際のクレデンシャル変数（git管理対象外）
    ├── .gitignore                         # .*.env を除外
    └── distfiles/                         # ビルド時にCOPYするファイル
        └── sshd_working_env.conf          # OpenSSH Server設定（Port 20022）
```

---

## 3. コンテナ環境の仕様

### ベースOS・ユーザー

| 項目 | 値 |
|---|---|
| ベースイメージ | `ubuntu:24.04` |
| ログインユーザー | `ubuntu`（uid=1000） |
| sudo権限 | NOPASSWD:ALL |
| 作業ディレクトリ（WORKDIR） | `/work/main` |

### インストール済みツール

| ツール | インストール方法 | 備考 |
|---|---|---|
| sudo, git, curl, wget, jq, vim, unzip | apt | 基本ツール |
| direnv | apt | ディレクトリ単位の環境変数管理 |
| openssh-server | apt | SSHサーバー（Port 20022） |
| gettext-base | apt | `envsubst`等のテンプレートツール |
| bind9-dnsutils | apt | `dig`等のDNSツール |
| groff | apt | manページ等テキスト整形 |
| build-essential | apt | miseによるソースビルド時に使用 |
| docker.io | apt | Docker CLI（ホストのDockerデーモンへソケット経由で接続） |
| AWS CLI v2 | curl（ビルド時ダウンロード） | `/usr/local/aws-cli/` |
| AWS Session Manager Plugin | curl（ビルド時ダウンロード） | AWS SSM経由のSSH接続用 |
| yq | curl（ビルド時ダウンロード） | `/usr/local/bin/yq` |
| mise | curl（ビルド時ダウンロード） | Node.js・Pythonなどのバージョン管理 |
| Claude Code | `claude.ai/install.sh` | AI Coding Agent本体 |

> **Note:** Node.jsおよびPythonは`apt`ではなく`mise`で管理します。

### mise の構成

| 設定 | パス |
|---|---|
| miseバイナリ | `/usr/local/bin/mise` |
| データ・シム・設定・キャッシュ | `/work/main/mise/` |
| PATH（シムモード） | `/work/main/mise/shims` |

- `~/.profile`（非対話セッション）: `mise activate bash --shims`
- `~/.bashrc`（対話セッション）: `mise activate bash`

---

## 4. ボリューム構成

| 用途 | ホスト側 | コンテナ側 | 種別 | 読み書き |
|---|---|---|---|---|
| 共有ディレクトリ（リポジトリ群） | `../`（親ディレクトリ） | `/work/shared` | バインドマウント | 読み書き |
| 主作業領域 | `work_main`（Dockerボリューム） | `/work/main` | 名前付きボリューム | 読み書き |
| git設定 | `~/.gitconfig` | `~/.gitconfig` | バインドマウント | 読取専用 |
| SSH鍵 | `~/.ssh` | `~/.ssh` | バインドマウント | 読取専用 |
| AWS認証情報 | `~/.aws` | `~/.aws` | バインドマウント | 読み書き |
| Claude Code設定 | `~/.claude` | `~/.claude` | バインドマウント | 読み書き |
| Dockerソケット | `/var/run/docker.sock` | `/var/run/docker.sock` | バインドマウント | 読み書き |

> **Note:** `/work/main`（`work_main`ボリューム）はコンテナをRebuildしても内容が保持されます。

---

## 5. 環境変数・クレデンシャル管理

### .env（非クレデンシャル、git管理対象）

コンテナビルド時に参照される変数を定義します。

| 変数名 | 値 | 用途 |
|---|---|---|
| `WORK_DIR` | `/work/main` | 主作業領域のパス |
| `SHARED_DIR` | `/work/shared` | 共有ディレクトリのパス |
| `WORK_DIR` | `/work/main` | 主作業領域のパス |
| `DOCKER_GID` | （ホスト側の値） | DockerグループのGID（WSL2側のdockerグループと合わせる） |

### .credential.env（クレデンシャル、git管理対象外）

`.gitignore`により`.*.env`パターンでgit管理から除外されています。実際の値は`.credential.env.sample`を参考に作成します。

| 変数名 | 用途 |
|---|---|
| `ANTHROPIC_API_KEY` | Claude Code用APIキー |

---

## 6. ポート一覧

| ポート | 用途 | VS Codeラベル |
|---|---|---|
| `5173` | Vite dev server（React等フロントエンド） | Frontend (Vite) |
| `8000` | Backend API（FastAPI等） | Backend API |
| `20022` | OpenSSH Server | OpenSSH Server |

OpenSSH Serverの設定（`sshd_working_env.conf`）:
- Port: `20022`
- PasswordAuthentication: `yes`

---

## 7. ライフサイクルスクリプト

### postCreateCommand.sh（コンテナ初回作成時に一度だけ実行）

実行パス: `../shared/.devcontainer/postCreateCommand.sh`（`/work/shared/.devcontainer/postCreateCommand.sh`）

| 条件 | 処理 |
|---|---|
| `backend/requirements.txt` が存在する場合 | `backend/.venv` にPython仮想環境を作成し、依存関係をインストール |
| `frontend/package.json` が存在する場合 | `frontend/` で `npm install` を実行 |

### postStartCommand.sh（コンテナ起動のたびに実行）

実行パス: `../shared/.devcontainer/postStartCommand.sh`（`/work/shared/.devcontainer/postStartCommand.sh`）

| 処理 | 詳細 |
|---|---|
| OpenSSH Server起動 | `/run/sshd`を作成し、ホスト鍵を生成して`sshd`を起動 |

> **Note:** postCreateCommand・postStartCommandのスクリプト本体は、このリポジトリの`postCreateCommand.sh`/`postStartCommand.sh`ではなく、`/work/shared/`配下（親ディレクトリ側）のスクリプトが実行されます。

---

## 8. VS Code 拡張機能・設定

### 拡張機能

| カテゴリ | 拡張機能 |
|---|---|
| TypeScript/React | ESLint, Prettier, Tailwind CSS IntelliSense |
| Python | Python, Black Formatter, mypy Type Checker |
| 汎用 | GitLens, Code Spell Checker, Path IntelliSense |

### エディタ設定

| 言語 | フォーマッター | 保存時フォーマット |
|---|---|---|
| Python | Black | 有効 |
| TypeScript | Prettier | 有効 |
| TypeScript React | Prettier | 有効 |

---

## 9. 作業上の注意事項

- **クレデンシャルをgitにコミットしない:** `.credential.env`などの`.*env`ファイルは`.gitignore`で除外されています。`.env`にはクレデンシャルを記載しないこと。
- **ツールのバージョン管理:** AWS CLI・SSM Plugin・yqのバージョンを変更する場合は、`Dockerfile`内のダウンロードURLを更新してからDockerイメージを再ビルドしてください。
- **Node.js・Pythonのバージョン管理:** `apt`ではなく`mise`で管理します。バージョン指定は`mise.toml`（`/work/main/`配下）で行います。
- **コンテナネットワーク:** `network_mode: host`を使用しているため、コンテナ内で起動したサービスはホストのポートを直接使用します。
