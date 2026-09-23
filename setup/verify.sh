#!/usr/bin/env bash
# Confirm the controllers and demo apps are ready. Exit 0 = ready to run samples.
. "$(dirname "$0")/../lib/common.sh"

problems=0
check() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else fail "$1"; problems=$((problems+1)); fi; }

banner "VERIFY  Gateway API + controllers"
check "Gateway API CRDs present"   "kubectl get crd httproutes.gateway.networking.k8s.io"
check "GatewayClass istio"         "kubectl get gatewayclass istio"
check "GatewayClass eg"            "kubectl get gatewayclass eg"
check "GatewayClass higress"       "kubectl get gatewayclass higress"
check "istiod ready"               "kubectl -n istio-system get deploy istiod -o jsonpath='{.status.availableReplicas}' | grep -q '[1-9]'"
check "istio ingress gateway"      "kubectl -n istio-system get deploy istio-ingressgateway -o jsonpath='{.status.availableReplicas}' | grep -q '[1-9]'"
check "ztunnel running"            "kubectl -n istio-system get ds ztunnel -o jsonpath='{.status.numberReady}' | grep -q '[1-9]'"
check "envoy gateway ready"        "kubectl -n envoy-gateway-system get deploy envoy-gateway -o jsonpath='{.status.availableReplicas}' | grep -q '[1-9]'"
check "higress controller ready"   "kubectl -n higress-system get deploy higress-controller -o jsonpath='{.status.availableReplicas}' | grep -q '[1-9]'"

banner "VERIFY  demo apps"
check "echo up (${NS_ISTIO})"      "kubectl -n ${NS_ISTIO} get deploy echo-v1 -o jsonpath='{.status.availableReplicas}' | grep -q '[1-9]'"
check "echo up (${NS_ENVOY})"      "kubectl -n ${NS_ENVOY} get deploy echo-v1 -o jsonpath='{.status.availableReplicas}' | grep -q '[1-9]'"
check "echo up (${NS_HIGRESS})"    "kubectl -n ${NS_HIGRESS} get deploy echo-v1 -o jsonpath='{.status.availableReplicas}' | grep -q '[1-9]'"
check "grpc-echo up (${NS_GRPC})"  "kubectl -n ${NS_GRPC} get deploy grpc-echo -o jsonpath='{.status.availableReplicas}' | grep -q '[1-9]'"

hr
if [ "${problems}" -eq 0 ]; then ok "ALL GREEN  ready to run: ./run.sh 1"; else fail "${problems} problem(s) to fix"; exit 1; fi
