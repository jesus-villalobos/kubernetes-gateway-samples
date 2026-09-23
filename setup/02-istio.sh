#!/usr/bin/env bash
# Install Istio in ambient mode, plus an ingress gateway. Ambient (ztunnel +
# istio-cni) powers the gRPC sample; the ingress gateway powers the Istio API
# regex-rewrite step. istioctl is downloaded locally into .istio/ (gitignored).
. "$(dirname "$0")/../lib/common.sh"

WORKDIR="${REPO_ROOT}/.istio"
ISTIOCTL="${WORKDIR}/istio-${ISTIO_VERSION}/bin/istioctl"

banner "Istio ${ISTIO_VERSION} (ambient profile + ingress gateway)"
if [ ! -x "${ISTIOCTL}" ]; then
  mkdir -p "${WORKDIR}"
  say "downloading istioctl ${ISTIO_VERSION}"
  run "curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh - >/dev/null"
  run "mv istio-${ISTIO_VERSION} ${WORKDIR}/ 2>/dev/null || true"
fi

# ambient gives ztunnel + istio-cni (chained onto the existing CNI, e.g. Calico);
# the ingress gateway is a standard Envoy deployment for north-south traffic.
run "${ISTIOCTL} install -y \
  --set profile=ambient \
  --set components.ingressGateways[0].enabled=true \
  --set components.ingressGateways[0].name=istio-ingressgateway"

wait_rollout istio-system deploy/istiod
run "kubectl -n istio-system rollout status ds/ztunnel --timeout=180s || true"
ok "Istio installed"
say "note: istio-cni chains onto the cluster's existing CNI; it does not replace it"
