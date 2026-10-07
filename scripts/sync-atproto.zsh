#!/bin/zsh

# Load environment configurations if .env exists
if [ -f .env ]; then
  source .env
fi

# Configuration fallbacks
PDS_URL="${ATPROTO_PDS_URL:-https://bsky.social}"
IDENTIFIER="${ATPROTO_IDENTIFIER}"
PASSWORD="${ATPROTO_APP_PASSWORD}"

if [[ -z "$IDENTIFIER" || -z "$PASSWORD" || -z "$ATPROTO_PUBLICATION_RKEY" ]]; then
  echo "Error: Missing ATPROTO_IDENTIFIER, ATPROTO_APP_PASSWORD, or ATPROTO_PUBLICATION_RKEY in environment."
  exit 1
fi

POSTS_DIR="./src/content/posts"
if [ ! -d "$POSTS_DIR" ]; then
  echo "Error: Posts directory not found at $POSTS_DIR"
  exit 1
fi

if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed. Please run: brew install yq"
  exit 1
fi

zmodload zsh/datetime

# Generate a TID record key from the current time
generate_tid() {
  local charset="234567abcdefghijklmnopqrstuvwxyz"
  local n=$(( (epochtime[1] * 1000000 + epochtime[2] / 1000) << 10 | (RANDOM & 1023) ))
  local tid="" i
  for i in {1..13}; do
    tid="${charset:$(( n & 31 )):1}$tid"
    n=$(( n >> 5 ))
  done
  echo "$tid"
}

echo "Authenticating with ATProto network..."

# Create a session to get the access token and DID
SESSION_RESP=$(curl -s -X POST "$PDS_URL/xrpc/com.atproto.server.createSession" \
  -H "Content-Type: application/json" \
  -d "{\"identifier\":\"$IDENTIFIER\", \"password\":\"$PASSWORD\"}")

TOKEN=$(echo "$SESSION_RESP" | jq -r '.accessJwt')
DID=$(echo "$SESSION_RESP" | jq -r '.did')

if [[ "$TOKEN" == "null" || -z "$TOKEN" ]]; then
  echo "Error: Authentication failed."
  echo "$SESSION_RESP"
  exit 1
fi

# Iterate over all mdx source files
for file in "$POSTS_DIR"/*.mdx(N); do
  [[ -e "$file" ]] || break

  FILENAME=$(basename "$file")
  ID="${FILENAME%.mdx}"

  # Safely extract ONLY the frontmatter header chunk to parse with yq
  FRONTMATTER_RAW=$(awk '/^---/{p++; if(p==2){print; exit}} p>=1' "$file")

  # Safely parse required properties out of the isolated frontmatter
  TITLE=$(echo "$FRONTMATTER_RAW" | yq '.title // ""')
  DESC=$(echo "$FRONTMATTER_RAW" | yq '.description // ""')
  PUB_DATE=$(echo "$FRONTMATTER_RAW" | yq '.pubDate // ""')
  EXISTING_URI=$(echo "$FRONTMATTER_RAW" | yq '.atprotoUri // ""')

  # Reuse the record key from a previous sync, otherwise mint a new TID
  if [[ -n "$EXISTING_URI" ]]; then
    RKEY="${EXISTING_URI##*/}"
  else
    RKEY=$(generate_tid)
  fi

  # Format standard date fallback
  if [[ -z "$PUB_DATE" ]]; then
    CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  else
    CREATED_AT=$(date -u -jf "%Y-%m-%d" "$PUB_DATE" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
  fi

  echo "Updating and overwriting PDS record for [$ID]..."

  # Generate valid site.standard.document JSON layout with the required publishedAt field
  JSON_PAYLOAD=$(jq -n \
      --arg did "$DID" \
      --arg pub "$ATPROTO_PUBLICATION_RKEY" \
      --arg path "/posts/$ID" \
      --arg title "${TITLE:-Untitled}" \
      --arg content "${DESC:-}" \
      --arg publishedAt "$CREATED_AT" \
      '{
        repo: $did,
        collection: "site.standard.document",
        rkey: "'"$RKEY"'",
        record: {
          "$type": "site.standard.document",
          site: ("at://" + $did + "/site.standard.publication/" + $pub),
          path: $path,
          title: $title,
          publishedAt: $publishedAt,
          content: {
            "$type": "site.standard.content.markdown",
            "text": $content,
            "version": "1.0"
          }
        }
      }')

  # We use putRecord here instead of createRecord to forcefully replace old schemas with the corrected layout
  RESPONSE=$(curl -s -X POST "$PDS_URL/xrpc/com.atproto.repo.putRecord" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$JSON_PAYLOAD")

  POST_ERR=$(echo "$RESPONSE" | jq -r '.error?')

  if [[ "$POST_ERR" != "null" && -n "$POST_ERR" ]]; then
    echo "Failed to update record [$ID]: $(echo "$RESPONSE" | jq -r '.message')"
    continue
  fi

  ATPROTO_URI=$(echo "$RESPONSE" | jq -r '.uri')
  echo "Successfully synchronized record: site.standard.document/$RKEY"

  # Clean check to ensure we only append the atprotoUri to your local markdown file if it isn't already present
  if [[ -z "$EXISTING_URI" && -n "$ATPROTO_URI" && "$ATPROTO_URI" != "null" ]]; then
    TEMP_FILE=$(mktemp)

    awk -v uri="$ATPROTO_URI" '
      /^---$/ {
        count++
        if (count == 2) {
          print "atprotoUri: \"" uri "\""
        }
      }
      { print }
    ' "$file" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$file"
    echo "Locally appended missing atprotoUri to $FILENAME"
  fi
done

echo "Sync execution sequence complete."
