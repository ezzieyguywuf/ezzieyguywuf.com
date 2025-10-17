#!/bin/bash

# Small script to make interacting with porkbun API a lil easier

# --- Argument Parsing ---
API_KEY=""
SECRET_KEY=""

usage() {
    echo "Usage: $0 --key-path <path_to_api_key> --secret-key-path <path_to_secret_key> <porkbun path> <json payload>"
    echo
    echo "  ex: bash porkbun.sh --key-path porkbun/api --secret-key porkbun/secret ping ''"
    echo "  ex: bash porkbun.sh --key-path porkbun/api --secret-key porkbun/secret domain/updateNs/foo.com '\"ns\": [ \"ns1.example.com\", \"ns2.example.com\"]'"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --key-path) API_KEY="$(pass show $2)"; shift ;;
        --secret-key-path) SECRET_KEY="$(pass show $2)"; shift ;;
        -*) echo "Unknown parameter passed: $1"; usage ;;
        *) break ;;
    esac
    shift
done

if [ -z "$API_KEY" ] || [ -z "$SECRET_KEY" ]; then
    echo "Error: Both --key-path and --secret-key-path are required."
    usage
fi

PORKBUN_PATH="$1"
JSON_PAYLOAD="$2"
# -------------------

JSON="{
  \"apikey\": \"${API_KEY}\",
  \"secretapikey\": \"${SECRET_KEY}\",
  ${JSON_PAYLOAD:-\"_nil\":\"\"}
}"

echo "apikey: ${API_KEY}"
echo "secretapikey: ${SECRET_KEY}"
echo "JSON: ${JSON}"
curl -X POST "https://api.porkbun.com/api/json/v3/${PORKBUN_PATH}" \
  -H "Content-Type: application/json" \
  -d "${JSON}"
echo
