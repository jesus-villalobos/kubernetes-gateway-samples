#!/usr/bin/env bash
# Install Higress from its public Helm repository. Higress is built on Istio and
# Envoy and supports the Gateway API plus Wasm plugins (used by the auth sample).
. "$(dirname "$0")/../lib/common.sh"

banner "Higress ${HIGRESS_CHART_VERSION}"
run "helm repo add higress.io https://higress.io/helm-charts 2>/dev/null || true"
run "helm repo update higress.io"
run "helm upgrade --install higress higress.io/higress \
  --version ${HIGRESS_CHART_VERSION} \
  -n higress-system --create-namespace \
  --set global.enableIstioAPI=true \
  --set higress-core.gateway.replicas=1"
wait_rollout higress-system deploy/higress-gateway
wait_rollout higress-system deploy/higress-controller
ok "Higress installed"
