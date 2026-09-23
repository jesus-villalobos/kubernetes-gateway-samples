#!/usr/bin/env bash
# Install the Kubernetes Gateway API CRDs (standard channel). All three
# implementations share these; install them once.
. "$(dirname "$0")/../lib/common.sh"

banner "Gateway API CRDs (${GATEWAY_API_VERSION}, standard channel)"
run "kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"
run "kubectl wait --for=condition=Established crd/httproutes.gateway.networking.k8s.io --timeout=60s"
ok "Gateway API CRDs installed"
