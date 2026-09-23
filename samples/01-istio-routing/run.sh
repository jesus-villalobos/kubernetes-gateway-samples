#!/usr/bin/env bash
# Sample 01 - Istio: portable Gateway API routing, plus regex path rewrite
# (an Istio capability the core Gateway API does not provide).
. "$(dirname "$0")/../../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

banner "SAMPLE 01  Istio: portable routing + regex rewrite"
step "1  the echo app is already running in ${NS_ISTIO}"
run "kubectl -n ${NS_ISTIO} get deploy,svc"
pause

step "2  apply a standard Gateway + HTTPRoute"
say "Path match, a header canary, a 90/10 split, and a core prefix rewrite, all in one portable file."
run "kubectl apply -f ${HERE}/gateway.yaml"
run "kubectl apply -f ${HERE}/httproute.yaml"
wait_gateway "${NS_ISTIO}" demo-gateway
wait_route "${NS_ISTIO}" echo-route
pfwd "${NS_ISTIO}" demo-gateway-istio "${LOCAL_ISTIO_K8S}" 80
pause

step "3  routing, canary, and weighted split"
say "Plain /echo: mostly v1, roughly 1 in 10 to v2."
run "for i in \$(seq 1 10); do curl -s -H 'Host: ${DEMO_HOST}' http://127.0.0.1:${LOCAL_ISTIO_K8S}/echo | jq -r '.environment.ECHO_VERSION // .host.hostname'; done | sort | uniq -c"
expect "about 9 v1, 1 v2"
pause
say "Preview header pins to v2 every time."
run "curl -s -H 'Host: ${DEMO_HOST}' -H 'x-preview: true' http://127.0.0.1:${LOCAL_ISTIO_K8S}/echo | jq -r '.environment.ECHO_VERSION'"
expect "v2"
pause

step "4  core prefix rewrite"
run "curl -s -H 'Host: ${DEMO_HOST}' http://127.0.0.1:${LOCAL_ISTIO_K8S}/legacy/foo | jq -r '.request.url'"
expect "the backend sees /foo, not /legacy/foo"
pause

step "5  regex rewrite (Istio API, beyond the core spec)"
say "Core Gateway API rewrites prefixes/full paths only. Regex rewrite needs Istio's VirtualService."
run "kubectl apply -f ${HERE}/istio-gw-regex.yaml"
pfwd istio-system istio-ingressgateway "${LOCAL_ISTIO_CLASSIC}" 80
run "curl -s -H 'Host: ${DEMO_HOST}' http://127.0.0.1:${LOCAL_ISTIO_CLASSIC}/api/v3/orders | jq -r '.request.url'"
expect "/orders?ver=v3"
pause

ok "Sample 01 complete."
pfwd_stop
