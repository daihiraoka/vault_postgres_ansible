#!/bin/bash
set -e

# Vault環境変数（devサーバ想定）
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=root

# 動的クレデンシャル取得
echo "# VaultからPostgreSQL用の一時認証情報を取得"
echo vault read -format=json database/creds/myapp
CREDS_JSON=$(vault read -format=json database/creds/myapp)

USERNAME=$(echo "$CREDS_JSON" | jq -r .data.username)
PASSWORD=$(echo "$CREDS_JSON" | jq -r .data.password)
LEASE_ID=$(echo "$CREDS_JSON" | jq -r .lease_id)
TTL=$(echo "$CREDS_JSON" | jq -r .lease_duration)

echo
echo "発行されたユーザー名: $USERNAME"
echo "発行されたパスワード: $PASSWORD"
echo "lease ID: $LEASE_ID"
echo "初期 TTL: ${TTL} 秒"
echo

echo "# PostgreSQLにユーザーが作成されたことを確認"
echo sudo -u postgres psql -c \"\\du\"
sudo -u postgres psql -c "\du" | grep "$USERNAME" || echo "(ユーザーが見つかりません)"

echo
echo "# 接続確認（取得直後）"
PGPASSWORD=$PASSWORD psql -U "$USERNAME" -h 127.0.0.1 -d postgres -c '\conninfo'

# TTLを延長
NEW_TTL=60
echo
echo "# leaseを延長します（${TTL}s → ${NEW_TTL}s）"
echo vault lease renew -increment=${NEW_TTL} "$LEASE_ID"
RENEWED=$(vault lease renew -increment=${NEW_TTL} "$LEASE_ID")

RENEWED_TTL=$(echo "$RENEWED" | grep lease_duration | awk '{print $2}')
echo "延長後 TTL: ${RENEWED_TTL} 秒"

echo
echo "# 再度接続確認（renew後）"
PGPASSWORD=$PASSWORD psql -U "$USERNAME" -h 127.0.0.1 -d postgres -c '\conninfo'

# leaseをrevoke
echo
echo "# leaseをrevoke（ユーザー削除）"
echo vault lease revoke "$LEASE_ID"
vault lease revoke "$LEASE_ID"

echo
echo "# PostgreSQLにユーザーが削除されたことを確認"
echo sudo -u postgres psql -c \"\\du\"
sudo -u postgres psql -c "\du" | grep "$USERNAME" || echo "(ユーザーは削除済み)"

