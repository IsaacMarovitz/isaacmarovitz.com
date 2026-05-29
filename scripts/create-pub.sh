if [ -f .env ]; then source .env; fi

# Force variable check
if [[ -z "$ATPROTO_IDENTIFIER" || -z "$ATPROTO_APP_PASSWORD" ]]; then
  echo "Error: Check your .env file. Missing ATPROTO_IDENTIFIER or ATPROTO_APP_PASSWORD."
  exit 1
fi

echo "Requesting clean authentication token from PDS..."

SESSION_RESP=$(curl -s -X POST "${ATPROTO_PDS_URL:-https://bsky.social}/xrpc/com.atproto.server.createSession" \
  -H "Content-Type: application/json" \
  -d "{\"identifier\":\"$ATPROTO_IDENTIFIER\", \"password\":\"$ATPROTO_APP_PASSWORD\"}")

PUB_TOKEN=$(echo "$SESSION_RESP" | jq -r '.accessJwt // empty')
PUB_DID=$(echo "$SESSION_RESP" | jq -r '.did // empty')

if [[ -z "$PUB_TOKEN" || "$PUB_TOKEN" == "null" ]]; then
  echo "Error: Authentication failed. Server response:"
  echo "$SESSION_RESP" | jq .
  exit 1
fi

NOW_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Pushing site.standard.publication record..."

curl -s -X POST "${ATPROTO_PDS_URL:-https://bsky.social}/xrpc/com.atproto.repo.putRecord" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $PUB_TOKEN" \
  -d "$(jq -n \
    --arg did "$PUB_DID" \
    --arg createdAt "$NOW_DATE" \
    '{
      repo: $did,
      collection: "site.standard.publication",
      rkey: "isaacmarovitz.com",
      record: {
        "$type": "site.standard.publication",
        name: "isaacmarovitz.com",
        url: "https://isaacmarovitz.com",
        description: "My personal blog.",
        createdAt: $createdAt
      }
    }')" | jq .
