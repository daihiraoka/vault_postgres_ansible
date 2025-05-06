#!/bin/bash
set -e

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# ========================
# TTL の設定を60秒に
# ========================
echo "# Vaultに動的PostgreSQLユーザー用ロールを再作成（default_ttl=60s, max_ttl=2m）"
vault write database/roles/myapp \
  db_name="postgres" \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT CONNECT ON DATABASE postgres TO \"{{name}}\";" \
  default_ttl="60s" \
  max_ttl="2m"

# ========================
# ユーザー発行
# ========================
echo
echo "# VaultからPostgreSQL用の一時認証情報を取得"
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

# ========================
# PostgreSQL 側で確認
# ========================
echo
echo "# PostgreSQLにユーザーが作成されたことを確認"
sudo -u postgres psql -c "\du" | grep "$USERNAME" || echo "(ユーザーがまだ見つかりません)"

# ========================
# 接続確認（直後）
# ========================
echo
echo "# 接続確認（取得直後）"
PGPASSWORD=$PASSWORD psql -U "$USERNAME" -h 127.0.0.1 -d postgres -c '\conninfo'

# ========================
# TTLが切れるのを待機（70秒）
# ========================
echo
echo "# TTL切れを待機中（70秒）"
sleep 70

# ========================
# 接続確認（TTL切れ後）
# ========================
echo
echo "# 接続確認（TTL切れ後）"
if PGPASSWORD=$PASSWORD psql -U "$USERNAME" -h 127.0.0.1 -d postgres -c '\conninfo'; then
  echo "(想定外：まだ接続できています)"
else
  echo "(想定通り：接続失敗。TTL切れでユーザーは無効化されました)"
fi

# ========================
# PostgreSQL 側で削除確認
# ========================
echo
echo "# PostgreSQLにユーザーが削除されたことを確認"
sudo -u postgres psql -c "\du" | grep "$USERNAME" && echo "(削除失敗？)" || echo "(ユーザーは削除済み)"

