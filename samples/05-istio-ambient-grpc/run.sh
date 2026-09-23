#!/usr/bin/env bash
# Sample 05 - Istio ambient: gRPC load balancing (L4 pin vs L7 spread) and
# east-west authorization. Shows why gRPC needs L7 to load balance across pods.
. "$(dirname "$0")/../../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

# Count handled requests per grpc-echo pod over a recent window and draw bars.
# Note: confirm the log pattern fortio emits per gRPC ping for your image tag.
tally_pods() {
  local since="${1:-40s}" p n bar
  for p in $(kubectl -n "${NS_GRPC}" get pods -l app=grpc-echo -o jsonpath='{.items[*].metadata.name}'); do
    n=$(kubectl -n "${NS_GRPC}" logs "$p" --since="$since" 2>/dev/null | grep -c -i 'ping' || echo 0)
    bar=$(printf '%0.s#' $(seq 1 $(( n>60 ? 60 : n )) ) 2>/dev/null || true)
    printf '%-28s %4d %s\n' "$p" "$n" "$bar"
  done
}

banner "SAMPLE 05  Istio ambient: gRPC load balancing + east-west authZ"
step "1  ambient is on (ztunnel), no waypoint yet"
run "kubectl -n ${NS_GRPC} get pods -o wide"
run "kubectl -n istio-system get ds ztunnel"
pause

step "2  L4 only: 100 gRPC calls over one connection pin to a single pod"
run "kubectl -n ${NS_GRPC} exec deploy/grpc-client -- fortio load -grpc -n 100 -c 1 grpc-echo:8079 >/tmp/fortio-l4.log 2>&1 || true"
say "Per-pod tally:"
tally_pods 40s
expect "one pod ~100, the others ~0"
pause

step "3  add the waypoint (a Gateway object) to enable L7"
run "kubectl apply -f ${HERE}/waypoint.yaml"
wait_gateway "${NS_GRPC}" waypoint
run "kubectl -n ${NS_GRPC} label service grpc-echo istio.io/use-waypoint=waypoint --overwrite"
run "sleep 6"
pause

step "4  rerun: the same 100 calls now spread across all pods"
run "kubectl -n ${NS_GRPC} exec deploy/grpc-client -- fortio load -grpc -n 100 -c 1 grpc-echo:8079 >/tmp/fortio-l7.log 2>&1 || true"
say "Per-pod tally:"
tally_pods 40s
expect "roughly 33 / 33 / 34 across the three pods"
pause

step "5  east-west authorization at the waypoint (optional)"
run "kubectl apply -f ${HERE}/authz.yaml"
run "sleep 5"
run "kubectl -n ${NS_GRPC} exec deploy/grpc-client -- fortio load -grpc -n 5 -c 1 grpc-echo:8079 >/tmp/fortio-authz.log 2>&1 || true; tail -n 3 /tmp/fortio-authz.log"
expect "the allowed client still succeeds; a non-allowed identity would be denied"
pause

ok "Sample 05 complete: L7 fixes gRPC load balancing and adds identity policy; the fix is a Gateway object."
say "Fallback if istio-cni does not chain onto this cluster's CNI: run the same point in sidecar mode (see README)."
