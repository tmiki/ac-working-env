FROM ubuntu:24.04
# ベースイメージ: Ubuntu 24.04 LTS
# ubuntu:24.04 には uid=1000 の "ubuntu" ユーザーがデフォルトで存在する

# docker-compose.yml から渡すビルド時引数を参照
ARG WORK_DIR
ARG SHARED_DIR
ARG LOGIN_USER
ARG DOCKER_GID


# ---- システムパッケージ（root で実行）----
# DEBIAN_FRONTEND=noninteractive でタイムゾーン等の対話プロンプトを抑制
ENV DEBIAN_FRONTEND=noninteractive

# 必要なパッケージ類のインストール
# ※ Node.js・Python は mise で管理するため apt からはインストールしない
RUN <<EOF_INSTALL_PKG
    # OSパッケージのインストール
    apt-get update
    apt-get install -y sudo locales ca-certificates git unzip curl wget jq vim gettext-base bind9-dnsutils groff direnv openssh-server docker.io
    # mise が一部ツールをソースビルドする際に必要なパッケージのインストール
    apt-get install -y build-essential

    # 必要な locale の作成
    locale-gen ja_JP.UTF-8 en_US.UTF-8

    # パッケージ外インストール
    cd /tmp

    #   AWS CLI v2のインストール
    #   Installing or updating to the latest version of the AWS CLI - AWS Command Line Interface
    #   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
    curl -L "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.34.42.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    #   AWS CLI SSM Session Manager pluginのインストール
    #   Install the Session Manager plugin on Debian Server and Ubuntu Server - AWS Systems Manager
    #   https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html
    curl -L "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    apt-get install -y ./session-manager-plugin.deb

    #   yqのインストール
    #   mikefarah/yq: yq is a portable command-line YAML, JSON, XML, CSV, TOML and properties processor
    #   https://github.com/mikefarah/yq
    curl -L "https://github.com/mikefarah/yq/releases/download/v4.53.2/yq_linux_amd64" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

    # インストール元ファイルの削除
    rm -rf ./aws/ ./awscliv2.zip ./session-manager-plugin.deb
EOF_INSTALL_PKG

# OpenSSH server用設定ファイルの追加
COPY distfiles/sshd_working_env.conf /etc/ssh/sshd_config.d/sshd_working_env.conf


# ---- mise のインストール（root で実行）----
#   バイナリ   → /usr/local/bin/mise     （全ユーザーから呼び出し可能）
#   シム       → ${WORK_DIR}/mise/shims  （PATH に追加することで透過的に利用）
#   データ     → ${WORK_DIR}/mise        （ツールの実体はここに格納）
ARG MISE_ROOT=${WORK_DIR}/mise
ENV MISE_INSTALL_PATH="/usr/local/bin/mise"
ENV MISE_DATA_DIR=${MISE_ROOT}
ENV MISE_CONFIG_DIR=${MISE_ROOT}
ENV MISE_CACHE_DIR=${MISE_ROOT}/cache
# ENV PATH=${MISE_ROOT}/shims:${PATH}

# mise をインストールし、対象ディレクトリを ubuntu ユーザーが書き込めるようにする
RUN curl -fsSL https://mise.run | sh \
    && mkdir -p ${MISE_ROOT} \
    && chown -R ${LOGIN_USER}:${LOGIN_USER} ${MISE_ROOT}

# ${WORK_DIR} を ubuntu ユーザが書き込めるようにする
RUN chown ${LOGIN_USER}:${LOGIN_USER} ${WORK_DIR}

# ---- ubuntu ユーザのパスワード初期化と、sudo 権限付与 ----
RUN echo "${LOGIN_USER}:${LOGIN_USER}" | chpasswd
RUN echo "${LOGIN_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${LOGIN_USER} \
    && chmod 0440 /etc/sudoers.d/${LOGIN_USER}

# DockerグループのGIDをWSL2側に合わせ、ログインユーザを追加
RUN groupmod -g ${DOCKER_GID} docker \
    && usermod -aG docker ${LOGIN_USER}

# ---- 以降は ubuntu ユーザーで実行 ----
USER ${LOGIN_USER}

# bash のタブ補完設定
RUN echo 'complete -C "$(command -v aws_completer)" aws' >> /home/${LOGIN_USER}/.bashrc
RUN echo 'source /usr/share/bash-completion/completions/git' >> /home/${LOGIN_USER}/.bashrc

# direnv 用のフックを設定
RUN echo 'eval "$(direnv hook bash)"' >> /home/${LOGIN_USER}/.bashrc

# mise 用のフックを設定
RUN echo 'eval "$(mise activate bash)"' >> /home/${LOGIN_USER}/.bashrc

# ---- Claude Code インストール ----
RUN curl -fsSL https://claude.ai/install.sh | bash

# ---- Dev Container の初期ログイン先ディレクトリを指定 ----
WORKDIR ${WORK_DIR}
