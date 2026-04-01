#!/usr/bin/env bash
set -euo pipefail

# Dev Container 起動時に実行される化スクリプト
echo "=== Dev Container 実行時セットアップ ==="

# sshd 
sudo mkdir -p /run/sshd && sudo chmod 0755 /run/sshd && sudo ssh-keygen -A && sudo /usr/sbin/sshd

echo "=== Dev Container 実行時セットアップ完了 ==="
