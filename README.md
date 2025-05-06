# HashiCorp Vault + PostgreSQL Dynamic Credentials 自動構成 Ansible Playbook

このプロジェクトは、**HashiCorp VaultとPostgreSQLの連携環境をAnsibleで自動構築**するためのPlaybookです。
HashiCorp VaultのDatabase Secrets Engineを使って、PostgreSQLに一時的なユーザーを発行・管理できます。

---

## このPlaybookでできること

* Vaultのインストール（公式リポジトリ利用）
* PostgreSQL 14のローカルインストールと初期設定
* VaultでのDatabaseエンジン有効化とPostgreSQLプラグイン設定
* 一時的なDBユーザー（TTL付き）の発行・削除の自動化

---

## 対応環境

* Ubuntu 22.04 LTS（それ以外は動作未確認）
* Ansible 2.10以上（推奨: `ansible-playbook --version`で確認）

---

## 事前に必要なツール

以下はAnsible Playbookが自動でインストールします：

* Vault CLI
* PostgreSQL（ローカル）
* curl / jq / gnupg などのユーティリティ

手動で必要なのは以下です：

* Ansible

  ```bash
  sudo apt update && sudo apt install -y ansible
  ```

---

## 利用方法

1. Playbookを実行します。

   ```bash
   ansible-playbook -i inventory.yml site.yml
   ```

   初回実行時、Vaultが開発モードで起動し、PostgreSQLも自動で起動されます。

2. 一時ユーザーの発行・確認は以下のスクリプトで行えます：

   ```bash
   bash vault_postgres_ttl_demo.sh
   ```

   このスクリプトは：

   * Vaultから一時ユーザーを発行し
   * PostgreSQLに接続できることを確認し
   * TTLを延長し
   * 最後にそのユーザーを削除します

---

## よくあるエラーと対処

* **Vault関連のAPIエラー（https エラー）**
  → Vault dev モードでは `http://` でアクセスしてください。

* **変数が未定義で失敗する**
  → `group_vars/all.yml` に以下の3つの変数を定義してください：

  ```yaml
  vault_root_token: root
  postgres_password: your_strong_password
  name: myapp
  ```

---

## 注意点

* このPlaybookは開発・検証用途向けです。
* Vaultは `-dev` モードで実行されており、再起動で状態がリセットされます。
* 本番環境ではTLSや永続ストレージなどの設定が必要です。

---

## ライセンス

MIT License

