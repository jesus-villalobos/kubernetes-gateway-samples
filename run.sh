#!/usr/bin/env bash
# Sample runner. Each sample demonstrates one Gateway API implementation.
#
#   ./run.sh            list the samples
#   ./run.sh 1          run sample 1 (Istio routing + regex rewrite)
#   ./run.sh 2          run sample 2 (Envoy Gateway rate limiting)
#   ./run.sh 3          run sample 3 (Envoy Gateway header manipulation)
#   ./run.sh 4          run sample 4 (Higress authentication)
#   ./run.sh 5          run sample 5 (Istio ambient gRPC)
#   ./run.sh all        run every sample in order
#   ./run.sh reset N    undo sample N so it can be re-run
#   AUTO=1 ./run.sh all unattended run with fixed pauses
. "$(dirname "$0")/lib/common.sh"

SAMPLES=(
  "01-istio-routing|Istio: portable routing (match, canary, split, prefix rewrite) + regex rewrite"
  "02-envoy-rate-limiting|Envoy Gateway: local vs global rate limiting, per-user ceilings"
  "03-envoy-header-manipulation|Envoy Gateway: header add/set/remove + client-IP detection"
  "04-higress-authentication|Higress: API-key authentication (401) + per-consumer authZ (403 vs 200)"
  "05-istio-ambient-grpc|Istio ambient: gRPC L4 pin vs L7 waypoint spread + east-west authZ"
)

list() {
  banner "Kubernetes Gateway API samples"
  local i=1 name desc
  for entry in "${SAMPLES[@]}"; do
    name="${entry%%|*}"; desc="${entry#*|}"
    printf '  %s  %-30s  %s\n' "$i" "${name}" "${desc}"
    i=$((i+1))
  done
  echo
  say "run one:  ./run.sh <N>     run all:  ./run.sh all     undo:  ./run.sh reset <N>"
  say "first time? install with:  bash setup/install-all.sh  then  bash setup/verify.sh"
}

sample_dir() { local n="$1"; local e="${SAMPLES[$((n-1))]}"; echo "${REPO_ROOT}/samples/${e%%|*}"; }
run_sample()   { bash "$(sample_dir "$1")/run.sh"; }
reset_sample() { bash "$(sample_dir "$1")/reset.sh"; }

case "${1:-}" in
  ""|list|-h|--help) list ;;
  all) for n in 1 2 3 4 5; do run_sample "$n"; done ;;
  reset) [ -n "${2:-}" ] || { fail "usage: ./run.sh reset <N>"; exit 1; }; reset_sample "$2" ;;
  [1-5]) run_sample "$1" ;;
  *) fail "unknown argument: $1"; list; exit 1 ;;
esac
