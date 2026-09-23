#!/usr/bin/env bash
# Sample 04 - Higress: authentication (401) and per-consumer authorization
# (403 vs 200) via the key-auth Wasm plugin.
. "$(dirname "$0")/../../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

banner "SAMPLE 04  Higress: authentication + authorization"
step "1  apply the gateway + route (open, no auth yet)"
run "kubectl apply -f ${HERE}/gateway.yaml"
wait_route "${NS_HIGRESS}" echo-route
pfwd_label higress-system "app=higress-gateway" "${LOCAL_HIGRESS}" 80
run "curl -s -o /dev/null -w 'open baseline: %{http_code}\n' -H 'Host: ${DEMO_HOST}' http://127.0.0.1:${LOCAL_HIGRESS}/echo"
expect "200 (no auth applied yet)"
pause

step "2  apply key-auth with two consumers and a gold-only allow-list"
run "kubectl apply -f ${HERE}/key-auth.yaml"
say "Give the Wasm plugin a few seconds to load."
run "sleep 10"
pause

step "3  authentication: no key is rejected"
run "curl -s -o /dev/null -w 'no key: %{http_code}\n' -H 'Host: ${DEMO_HOST}' http://127.0.0.1:${LOCAL_HIGRESS}/echo"
expect "401"
pause

step "4  authorization: a valid bronze key is authenticated but not allowed here"
run "curl -s -o /dev/null -w 'bronze key: %{http_code}\n' -H 'Host: ${DEMO_HOST}' -H 'x-api-key: cred-bronze-uvwxyz' http://127.0.0.1:${LOCAL_HIGRESS}/echo"
expect "403 (known consumer, not on the allow-list)"
pause

step "5  the gold key is allowed"
run "curl -s -o /dev/null -w 'gold key: %{http_code}\n' -H 'Host: ${DEMO_HOST}' -H 'x-api-key: cred-gold-abcdef' http://127.0.0.1:${LOCAL_HIGRESS}/echo"
expect "200"
pause

ok "Sample 04 complete: one plugin gave the edge authentication (401) and per-consumer authorization (403 vs 200), no app code."
pfwd_stop
