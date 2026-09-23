#!/usr/bin/env bash
# Install everything the samples need, in order, into the current cluster.
# Safe to re-run; each step is idempotent.
. "$(dirname "$0")/../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

banner "Installing Gateway API + Istio + Envoy Gateway + Higress + demo apps"
bash "${HERE}/01-gateway-api.sh"
bash "${HERE}/02-istio.sh"
bash "${HERE}/03-envoy-gateway.sh"
bash "${HERE}/04-higress.sh"
bash "${HERE}/05-apps.sh"

ok "install complete"
say "run 'bash setup/verify.sh' to confirm everything is ready, then './run.sh 1'"
