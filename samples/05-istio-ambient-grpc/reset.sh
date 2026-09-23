#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
run "kubectl delete -f ${HERE}/authz.yaml --ignore-not-found"
run "kubectl -n ${NS_GRPC} label service grpc-echo istio.io/use-waypoint- --overwrite || true"
run "kubectl delete -f ${HERE}/waypoint.yaml --ignore-not-found"
ok "sample 05 reset"
