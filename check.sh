#!/usr/bin/env bash
# Runs one AgentsReady check and reports it in the job summary, a PR comment and step outputs.
set -euo pipefail

API="${AGENTSREADY_API:-https://agentsready.dev/api/check}"
out="$(mktemp)"
code=$(curl -sS -G "$API" --data-urlencode "domain=$DOMAIN" ${JOB:+--data-urlencode "job=$JOB"} \
  -A "agentsready-action/1 (+https://github.com/itspsneha/agentsready-action)" \
  --max-time 120 -o "$out" -w '%{http_code}' || echo 000)
if [ "$code" != "200" ]; then
  echo "::error title=AgentsReady::Check failed (HTTP $code): $(head -c 300 "$out")"
  exit 1
fi

score=$(jq -r .score "$out")
level=$(jq -r .level "$out")
wall=$(jq -r .bot_wall "$out")
report=$(jq -r .report "$out")
badge=$(jq -r .badge "$out")
{
  echo "score=$score"
  echo "level=$level"
  echo "bot_wall=$wall"
  echo "report=$report"
} >> "$GITHUB_OUTPUT"

body="$(mktemp)"
{
  echo "<!-- agentsready-action -->"
  echo "### [![Agent ready score]($badge)]($report) $DOMAIN: $score/100, $level"
  echo
  echo "Job an agent tried: **$(jq -r .job_name "$out")** · core $(jq -r .core "$out") · job $(jq -r .job_points "$out")"
  [ "$wall" = "true" ] && echo && echo "> **A bot wall blocks AI agents.** ChatGPT, Claude and Perplexity can't read this site."
  echo
  echo "| AI agent | Gets the real page |"
  echo "| --- | --- |"
  jq -r '.agent_access[] | "| \(.agent) | \(if .allowed then "yes" else "no (\(.blocked_by))" end) |"' "$out"
  echo
  if [ "$(jq '.fixes | length' "$out")" -gt 0 ]; then
    echo "**Fixes, biggest first**"
    echo
    jq -r '.fixes[] | "- [ ] **\(.check)** (+\(.points)): \(.fix)"' "$out"
    echo
  fi
  echo "<details><summary>Paste this into your coding agent</summary>"
  echo
  echo '```text'
  jq -r .prompt "$out"
  echo '```'
  echo "</details>"
  echo
  echo "[Full report]($report) · results are cached for up to 24 hours · [AgentsReady](https://agentsready.dev/?utm_source=github&utm_medium=action)"
} > "$body"

cat "$body" >> "$GITHUB_STEP_SUMMARY"

if [ -n "${PR:-}" ] && [ "$COMMENT" = "true" ]; then
  # One comment per PR, edited on each run.
  id=$(gh api "repos/$REPO/issues/$PR/comments" --paginate -q '.[] | select(.body | startswith("<!-- agentsready-action -->")) | .id' 2>/dev/null | head -n1 || true)
  if [ -n "$id" ]; then
    gh api -X PATCH "repos/$REPO/issues/comments/$id" -F body=@"$body" >/dev/null || echo "::warning::Couldn't update the PR comment"
  else
    gh api "repos/$REPO/issues/$PR/comments" -F body=@"$body" >/dev/null || echo "::warning::Couldn't comment on the PR (does the job have pull-requests: write?)"
  fi
fi

echo "$DOMAIN: $score/100 ($level). Report: $report"
if [ "$FAIL_ON_WALL" = "true" ] && [ "$wall" = "true" ]; then
  echo "::error title=AgentsReady::A bot wall blocks AI agents on $DOMAIN"
  exit 1
fi
if [ "$score" -lt "$FAIL_UNDER" ]; then
  echo "::error title=AgentsReady::Score $score is below fail-under $FAIL_UNDER"
  exit 1
fi
