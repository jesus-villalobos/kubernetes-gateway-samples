#!/usr/bin/env bash
. "$(dirname "$0")/../../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
run "kubectl delete -f ${HERE}/clienttrafficpolicy.yaml --ignore-not-found"
run "kubectl delete -f ${HERE}/headers-route.yaml --ignore-not-found"
ok "sample 03 reset"
