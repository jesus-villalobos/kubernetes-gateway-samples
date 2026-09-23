#!/usr/bin/env bash
# Sample 02 - Envoy Gateway: local then global rate limiting, per-user.
. "$(dirname "$0")/../../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

banner "SAMPLE 02  Envoy Gateway: rate limiting (local, then global per user)"
step "1  apply the same portable route shape on a different engine"
run "kubectl apply -f ${HERE}/gateway.yaml"
wait_gateway "${NS_ENVOY}" eg-gateway
wait_route "${NS_ENVOY}" echo-route
pfwd_label envoy-gateway-system "gateway.envoyproxy.io/owning-gateway-name=eg-gateway" "${LOCAL_ENVOY}" 80
run "curl -s -o /dev/null -w 'baseline: %{http_code}\n' -H 'Host: ${DEMO_HOST}' http://127.0.0.1:${LOCAL_ENVOY}/echo"
expect "200"
pause

step "2  LOCAL rate limit (per-replica, 5/min)"
run "kubectl apply -f ${HERE}/ratelimit-local.yaml"
run "sleep 8"
say "12 requests: first few pass, the rest are limited (429)."
burst 12 "${LOCAL_ENVOY}" /echo
expect "about 5 OK, then -- (429)"
pause

step "3  swap LOCAL for GLOBAL, keyed per user"
run "kubectl delete -f ${HERE}/ratelimit-local.yaml --ignore-not-found"
run "kubectl apply -f ${HERE}/ratelimit-global.yaml"
run "sleep 8"
pause

step "4  same endpoint, two users, two outcomes"
say "Bronze (limit 3/min) trips quickly."
burst 8 "${LOCAL_ENVOY}" /echo -H "x-user: bronze"
expect "about 3 OK, then -- (429)"
pause
say "Gold (limit 100/min), identical requests, stays green."
burst 8 "${LOCAL_ENVOY}" /echo -H "x-user: gold"
expect "8 OK"
pause

ok "Sample 02 complete: local vs global rate limiting, and per-user ceilings."
pfwd_stop
