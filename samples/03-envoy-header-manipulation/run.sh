#!/usr/bin/env bash
# Sample 03 - Envoy Gateway: header manipulation and client-IP handling.
. "$(dirname "$0")/../../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

banner "SAMPLE 03  Envoy Gateway: header manipulation + client IP"
step "1  apply the header-modifying route"
run "kubectl apply -f ${HERE}/headers-route.yaml"
wait_gateway "${NS_ENVOY}" eg-hdr-gateway
wait_route "${NS_ENVOY}" echo-hdr-route
pfwd_label envoy-gateway-system "gateway.envoyproxy.io/owning-gateway-name=eg-hdr-gateway" "${LOCAL_ENVOY}" 80
pause

step "2  the request headers the app receives are rewritten by the gateway"
say "We send an internal-only header; the gateway strips it and injects its own. The app echoes what it actually received."
run "curl -s -H 'Host: ${DEMO_HOST}' -H 'x-internal-only: should-be-removed' http://127.0.0.1:${LOCAL_ENVOY}/echo | jq '.request.headers | {x_demo_added: .\"x-demo-added\", x_demo_tier: .\"x-demo-tier\", x_internal_only: .\"x-internal-only\"}'"
expect "x-demo-added and x-demo-tier present; x-internal-only is null (removed)"
pause

step "3  response headers added on the way out"
run "curl -s -D - -o /dev/null -H 'Host: ${DEMO_HOST}' http://127.0.0.1:${LOCAL_ENVOY}/echo | grep -i x-demo-response"
expect "x-demo-response: seen-on-the-way-out"
pause

step "4  advanced: client-IP detection into X-Forwarded-For"
say "This ClientTrafficPolicy is Envoy-Gateway-specific; core Gateway API has no client-IP primitive."
run "kubectl apply -f ${HERE}/clienttrafficpolicy.yaml"
run "sleep 6"
run "curl -s -H 'Host: ${DEMO_HOST}' http://127.0.0.1:${LOCAL_ENVOY}/echo | jq '.request.headers | {xff: .\"x-forwarded-for\"}'"
expect "x-forwarded-for populated with the caller's address"
pause

ok "Sample 03 complete: portable header add/set/remove, plus Envoy-native client-IP handling."
pfwd_stop
