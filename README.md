# Vault + PostgreSQL Dynamic Credentials 自動構成（Ansible）

このリポジトリは、HashiCorp Vault と PostgreSQL を連携させて、動的にユーザー認証情報を発行・管理する構成を Ansible で自動化するものです。

## セットアップ手順

### 前提ツール

次のツールがインストールされていることを前提とします。

* Ansible 2.10 以上
* Vault CLI
* PostgreSQL（ローカルインストール）
* curl, jq, gnupg などの基本ユーティリティ

### 実行方法

以下のコマンドで Vault と PostgreSQL のインストールおよび構成を行います。

```
ansible-playbook -i inventory.yml site.yml
```

## Playbook 構成

### roles/install\_packages/

基本的なユーティリティパッケージ（curl, gnupg, jq）のインストールを行います。

### roles/install\_vault/

* Vault GPGキーの登録
* Vault のリポジトリ追加とインストール
* 開発モードでの Vault 起動
* VAULT\_ADDR 環境変数の設定

### roles/install\_postgresql/

* PostgreSQL と postgresql-contrib のインストール
* postgres ユーザーの初期パスワード設定
* PostgreSQL サービスの起動

### roles/setup\_vault\_database\_engine/

* Vault の Database secrets engine を有効化
* PostgreSQL 接続情報（connection\_url）の登録
* 動的ユーザー作成のための role（myapp）を登録

## 確認用シェルスクリプト

`shell/vault_postgres_ttl_demo.sh` により、以下の一連の動作確認を行うことができます。

1. Vault に role を登録
2. Vault から一時的な PostgreSQL 認証情報を取得
3. PostgreSQL にユーザーが作成されたことを確認
4. psql を使った接続確認
5. lease の TTL を延長
6. lease を revoke し、ユーザーが削除されたことを確認

## 管理する変数

以下の変数は `group_vars/all.yml` に定義されています。

```
vault_root_token: root
postgres_password: your_strong_password
name: myapp
```

本番運用では、Ansible Vault などで暗号化することを推奨します。

## ディレクトリ構成

```
vault_postgres_ansible/
├── inventory.yml
├── site.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── install_packages/
│   ├── install_vault/
│   ├── install_postgresql/
│   └── setup_vault_database_engine/
└── shell/
    └── vault_postgres_ttl_demo.sh
```

## 注意事項

この構成は検証・学習目的を想定しており、Vault は dev モードで起動しています。本番利用の際は、TLS や認証制御の導入を含むセキュリティ対策を別途実施してください。
