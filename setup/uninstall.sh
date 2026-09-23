#!/usr/bin/env bash
# Remove the samples, demo apps, and controllers. Or just delete your cluster.
. "$(dirname "$0")/../lib/common.sh"

banner "Removing demo apps and namespaces"
for ns in "${NS_ISTIO}" "${NS_ENVOY}" "${NS_HIGRESS}" "${NS_GRPC}"; do
  run "kubectl delete namespace ${ns} --ignore-not-found"
done

banner "Removing controllers"
run "helm uninstall higress -n higress-system --ignore-not-found || true"
run "kubectl delete namespace higress-system --ignore-not-found"
run "kubectl delete -f https://github.com/envoyproxy/gateway/releases/download/${ENVOY_GATEWAY_VERSION}/install.yaml --ignore-not-found || true"
ISTIOCTL="${REPO_ROOT}/.istio/istio-${ISTIO_VERSION}/bin/istioctl"
[ -x "${ISTIOCTL}" ] && run "${ISTIOCTL} uninstall --purge -y || true"
run "kubectl delete namespace istio-system --ignore-not-found"

say "Gateway API CRDs are left in place; remove them manually if desired."
ok "uninstall complete"
