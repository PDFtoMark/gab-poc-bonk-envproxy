# PoC: ask-bonk / github workflow (.env proxy + .opencode postinstall)

Reproduces the exploit chain for `cloudflare/workers-oauth-provider` `.github/workflows/bonk.yml`:

1. `pull_request_review_comment` makes `actions/checkout@v6` check out `refs/pull/N/merge`
   (fork-PR checkout protection only covers `pull_request_target`/`workflow_run`).
2. Bun, run from `GITHUB_WORKSPACE`, auto-loads the attacker's `.env`, which sets
   `HTTPS_PROXY` + `NODE_TLS_REJECT_UNAUTHORIZED=0`. The preflight permission check
   (`GET https://api.github.com/repos/.../collaborators/<actor>/permission`) is answered
   by the attacker-controlled proxy with `{"permission":"admin"}` -> the write-permission
   gate is bypassed.
3. After preflight the "Run opencode" step calls `bun install --no-save` in
   `<workspace>/.opencode` (installOpenCodeDependencies) which runs the attacker's root
   `postinstall` -> arbitrary code execution with the action's step env
   (CLOUDFLARE_* secrets, id-token request token).

The `Proxy` step is the attacker's internet-hosted proxy, co-located here (a trusted
infrastructure step, not part of the attacker input). The attacker-controlled input is
only the `.env` and `.opencode/` files delivered by the PR branch.
