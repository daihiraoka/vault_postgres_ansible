#!/bin/bash
set -e

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo "# Vaultに動的PostgreSQLユーザー用ロールを作成（default_ttl=60s, max_ttl=5m）"
vault write database/roles/myapp \
  db_name="postgres" \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT CONNECT ON DATABASE postgres TO \"{{name}}\";" \
  default_ttl="60s" \
  max_ttl="5m"

echo
echo "# VaultからPostgreSQL用の一時認証情報を取得"
echo "vault read -format=json database/creds/myapp"
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
sudo -u postgres psql -c "\du" | grep "$USERNAME" || echo "(ユーザーがまだ見つかりません)"

echo
echo "# 接続確認（取得直後）"
PGPASSWORD=$PASSWORD psql -U "$USERNAME" -h 127.0.0.1 -d postgres -c '\conninfo'

echo
echo "# TTLを延長します（例: 240秒）"
echo "vault lease renew -increment=240 $LEASE_ID"
RENEW_RESULT=$(vault lease renew -increment=240 "$LEASE_ID")
NEW_TTL=$(echo "$RENEW_RESULT" | grep lease_duration | awk '{print $2}')
echo "延長後 TTL: ${NEW_TTL} 秒"

echo
echo "# 再度接続確認（renew後）"
PGPASSWORD=$PASSWORD psql -U "$USERNAME" -h 127.0.0.1 -d postgres -c '\conninfo'

echo
echo "# leaseをrevoke（ユーザー削除）"
echo "vault lease revoke $LEASE_ID"
vault lease revoke "$LEASE_ID"

echo
echo "# PostgreSQLにユーザーが削除されたことを確認"
sudo -u postgres psql -c "\du" | grep "$USERNAME" && echo "(削除失敗？)" || echo "(ユーザーは削除済み)"
