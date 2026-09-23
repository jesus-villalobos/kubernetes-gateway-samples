#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
run "kubectl delete -f ${HERE}/istio-gw-regex.yaml --ignore-not-found"
run "kubectl delete -f ${HERE}/httproute.yaml --ignore-not-found"
run "kubectl delete -f ${HERE}/gateway.yaml --ignore-not-found"
ok "sample 01 reset"
