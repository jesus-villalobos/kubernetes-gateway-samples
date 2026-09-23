#!/usr/bin/env bash
# Install Envoy Gateway from its published GitHub release manifest (no OCI/helm
# needed), register its GatewayClass, and enable global rate limiting (backed by
# a small Redis) so the rate-limiting sample can show both local and global.
. "$(dirname "$0")/../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

banner "Envoy Gateway ${ENVOY_GATEWAY_VERSION}"
run "kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/${ENVOY_GATEWAY_VERSION}/install.yaml"
wait_rollout envoy-gateway-system deploy/envoy-gateway

banner "Envoy Gateway: GatewayClass + global rate limit backend (Redis)"
run "kubectl apply -f ${HERE}/envoy-gatewayclass.yaml"
run "kubectl apply -f ${HERE}/envoy-ratelimit-infra.yaml"
run "kubectl -n envoy-gateway-system rollout restart deploy/envoy-gateway"
wait_rollout envoy-gateway-system deploy/envoy-gateway
ok "Envoy Gateway installed"
