# HashiCorp Vault + PostgreSQL Dynamic Credentials 自動構成 Ansible Playbook

このプロジェクトは、**HashiCorp VaultとPostgreSQLの連携環境をAnsibleで自動構築**するためのPlaybookです。
HashiCorp VaultのDatabase Secrets Engineを使って、PostgreSQLに一時的なユーザーを発行・管理できます。

## ディレクトリ構成

```
.
├── README.md
├── group_vars/
│   └── all.yml             # 変数定義（Vault トークン、DB パスワードなど）
├── inventory.ini          # localhost 用インベントリ
├── roles/                 # 各構成ロール
│   ├── install_packages/
│   ├── install_vault/
│   ├── install_postgresql/
│   └── setup_vault_database_engine/
├── shell/
│   └── vault_postgres_ttl_demo.sh  # 検証用シェルスクリプト
└── site.yml               # メイン Playbook
```

## 機能概要

* Vault のインストールと設定（dev モード）
* PostgreSQL のインストールと設定（ローカル）
* Vault への PostgreSQL データベースエンジンの有効化
* Vault による動的ユーザーのロール作成
* 一時ユーザーの取得・TTL 更新・削除デモスクリプト付き

## 前提ツール

以下は ansible 実行時に自動でインストールされます：

* curl
* jq
* gnupg
* Vault CLI
* PostgreSQL（ローカルインストール）

以下は事前に用意しておく必要があります：

* Ansible（バージョン 2.10 以上推奨）

## 使い方

### 1. 事前準備：Ansible のインストール

本Playbookを実行するには、あらかじめAnsibleをインストールしておく必要があります。

Ubuntu の場合は以下のコマンドでインストールできます：

```bash
sudo apt update
sudo apt install -y ansible
````

インストール後、Ansible のバージョン確認をおすすめします：

```bash
ansible --version
```

Ansible バージョン 2.10 以上であることを確認してください。


### 2. リポジトリのクローン

```bash
git clone https://github.com/daihiraoka/vault_postgres_ansible.git
cd vault_postgres_ansible
```

### 3. Ansible Playbook の実行

以下のコマンドで自動構成を実行します：

```bash
ansible-playbook -i inventory.ini site.yml
```

構成完了後、Vault と PostgreSQL が起動し、Vault による動的クレデンシャル発行が可能になります。

### 4. 動的クレデンシャルの動作確認（任意）

`shell/vault_postgres_ttl_demo.sh` を実行することで、以下の動作を確認できます：

* Vault にロールを作成
* 一時ユーザーを取得
* PostgreSQL 接続確認
* TTL の延長
* ユーザーの削除（lease revoke）

```bash
bash shell/vault_postgres_ttl_demo.sh
```

## 手動手順（学習用）

Ansible を使わずに手動で Vault と PostgreSQL を連携させる基本操作です。Vault の CLI に慣れるために有効です。

### 1. Vault dev サーバ起動

```bash
vault server -dev &
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'
```

### 2. PostgreSQL を起動・ログイン（必要に応じて）

```bash
sudo service postgresql start
sudo -u postgres psql
```

### 3. Vault に Database Secrets Engine をマウント

```bash
vault secrets enable database
```

### 4. PostgreSQL 接続設定を登録

```bash
vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles=myapp \
  connection_url="postgresql://postgres:your_strong_password@127.0.0.1:5432/postgres?sslmode=disable"
```

### 5. ロール作成（動的ユーザー用）

```bash
vault write database/roles/myapp \
  db_name=postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl="60s" \
  max_ttl="5m"
```

### 6. 一時ユーザーの取得

```bash
vault read database/creds/myapp
```

### 7. TTL の延長

```bash
vault lease renew -increment=240 <lease_id>
```

### 8. ユーザーの削除（revoke）

```bash
vault lease revoke <lease_id>
```

