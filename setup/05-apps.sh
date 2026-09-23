#!/usr/bin/env bash
# Deploy the demo apps. The HTTP echo app runs in each gateway's namespace; the
# gRPC app runs in an ambient-enrolled namespace for the mesh sample.
. "$(dirname "$0")/../lib/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

banner "Demo apps: HTTP echo (per gateway) + gRPC echo (ambient)"

for ns in "${NS_ISTIO}" "${NS_ENVOY}" "${NS_HIGRESS}"; do
  run "kubectl create namespace ${ns} --dry-run=client -o yaml | kubectl apply -f -"
  run "kubectl -n ${ns} apply -f ${HERE}/../apps/echo.yaml"
  wait_rollout "${ns}" deploy/echo-v1
done

# gRPC namespace is enrolled into the ambient mesh.
run "kubectl create namespace ${NS_GRPC} --dry-run=client -o yaml | kubectl apply -f -"
run "kubectl label namespace ${NS_GRPC} istio.io/dataplane-mode=ambient --overwrite"
run "kubectl -n ${NS_GRPC} apply -f ${HERE}/../apps/grpc-echo.yaml"
wait_rollout "${NS_GRPC}" deploy/grpc-echo
wait_rollout "${NS_GRPC}" deploy/grpc-client

ok "demo apps deployed"
