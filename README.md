# kubernetes-gateway-samples

Hands-on, runnable samples that show how to use the [Kubernetes Gateway
API](https://gateway-api.sigs.k8s.io/) with several open-source
implementations, side by side, on a single throwaway cluster.

The Gateway API is one portable standard, but each implementation adds its own
capabilities on top. These samples let you *see* both halves: the same portable
`HTTPRoute` running on different engines, and the engine-specific features
(rate limiting, header manipulation, authentication, mesh traffic) that go
beyond the core spec.

Everything here uses only public projects and images. There is nothing to buy
and nothing private; clone it and run.

## What you get

| Sample | Implementation | Shows |
|--------|----------------|-------|
| `01-istio-routing`            | Istio            | Portable routing (path match, header canary, weighted split, prefix rewrite), then regex path rewrite, a capability the core Gateway API does not have |
| `02-envoy-rate-limiting`      | Envoy Gateway    | Local (per-replica) rate limiting, then global (shared) rate limiting with different limits per user |
| `03-envoy-header-manipulation`| Envoy Gateway    | Add / set / remove request and response headers, plus client-IP detection into `X-Forwarded-For` |
| `04-higress-authentication`   | Higress          | API-key authentication (401 without a key) and per-consumer authorization (403 vs 200) |
| `05-istio-ambient-grpc`       | Istio (ambient)  | Why gRPC needs L7 load balancing: requests pin to one pod at L4, then spread across pods once a waypoint is added; plus identity-based authorization |

All five run in one cluster, separated by namespace and GatewayClass. The three
gateway controllers (Istio, Envoy Gateway, Higress) coexist happily, each owns
its own GatewayClass.

## Requirements

- A Kubernetes cluster you can throw away. Anything works:
  [KodeKloud playground](https://kodekloud.com/), `kind`, `minikube`, k3s, or
  any kubeadm cluster with internet access for image pulls.
- `kubectl`, `helm`, and `curl` on your PATH. The Istio sample also downloads
  `istioctl` for you.
- `jq` is used to pretty-print a few responses (optional but nice).
- `k9s` is optional. It gives a live visual view of the resources while the
  samples run. Install it with `bash setup/install-k9s.sh` (see "Using k9s").

No LoadBalancer is required: the samples reach gateways with
`kubectl port-forward`, so they work even on clusters with no cloud load
balancer (like most playgrounds).

## Quickstart

```bash
git clone https://github.com/jesus-villalobos/kubernetes-gateway-samples.git
cd kubernetes-gateway-samples

# 1. Install the Gateway API CRDs and the three implementations (a few minutes).
bash setup/install-all.sh

# 2. Confirm everything is ready.
bash setup/verify.sh

# 3. Run a sample. Press Enter to advance through each step.
./run.sh 1      # Istio routing
./run.sh 2      # Envoy Gateway rate limiting
./run.sh 3      # Envoy Gateway header manipulation
./run.sh 4      # Higress authentication
./run.sh 5      # Istio ambient gRPC load balancing

# List everything, or undo a sample so you can re-run it:
./run.sh
./run.sh reset 2
```

Each sample prints every command before it runs it, states what to expect, then
shows the real output, so you can follow along or read the scripts as a guide.

## Using k9s (optional visual pane)

The samples prove behavior through request/response (`curl` status codes, header
dumps, per-pod request counts), so the terminal is where the payoff shows up.
[k9s](https://k9scli.io/) is a great companion for the other half: *seeing*
resources reconcile and reading logs while a sample runs.

```bash
bash setup/install-k9s.sh          # installs k9s locally (via webi)
source ~/.config/envman/PATH.env   # add k9s to PATH in this shell
export K9S_CONFIG_DIR="$PWD/k9s"   # use this repo's aliases
k9s
```

A two-pane layout works well:

- Pane A (k9s): watch the Gateway flip to `Programmed`, the HTTPRoute to
  `Accepted`, the Envoy/waypoint pods appear, and tail gateway logs.
- Pane B (`./run.sh N`): applies the YAML and runs the request tests.

The samples pause between "apply" and "test," so you can flip to k9s and show
reconciliation before running the proof.

Handy inside k9s (aliases provided in `k9s/aliases.yaml`):

| Type this | Jumps to |
|-----------|----------|
| `:gw`     | Gateways |
| `:route`  | HTTPRoutes |
| `:gc`     | GatewayClasses |
| `:btp`    | Envoy Gateway BackendTrafficPolicies (rate limits) |
| `:ctp`    | Envoy Gateway ClientTrafficPolicies (client IP) |
| `:vs`     | Istio VirtualServices (regex rewrite) |
| `:wasm`   | Higress WasmPlugins (auth) |
| `:authz`  | Istio AuthorizationPolicies (ambient) |

Native k9s keys that pair well: `l` (logs), `d` (describe), `y` (view YAML),
`Shift-F` (port-forward), `0`/`<num>` to filter namespaces.

## How it is laid out

```
kubernetes-gateway-samples/
  versions.env          pinned versions, namespaces, ports, demo hostname
  lib/common.sh         tiny helper library (print-then-run, port-forward, request bursts)
  setup/
    install-all.sh      runs the steps below in order
    01-gateway-api.sh   install Gateway API CRDs (standard channel)
    02-istio.sh         install Istio (ambient profile + an ingress gateway)
    03-envoy-gateway.sh install Envoy Gateway (from its GitHub release manifest)
    04-higress.sh       install Higress (from its public Helm repo)
    05-apps.sh          deploy the demo apps (HTTP echo, gRPC echo)
    install-k9s.sh      install the optional k9s terminal UI
    verify.sh           check controllers and apps are ready
    uninstall.sh        remove everything
  apps/                 echo (HTTP, reflects the request) and grpc-echo (fortio)
  k9s/aliases.yaml      k9s aliases for the CRDs these samples use
  samples/NN-name/      one folder per sample: the YAML applied, run.sh, reset.sh
  run.sh                the sample runner
```

## Notes for playground clusters (KodeKloud, etc.)

- These are typically 2-node kubeadm clusters with a CNI already installed
  (often Calico/Canal). That is fine. Istio's ambient install adds `istio-cni`
  as a *chained* plugin on top of the existing CNI, it does not replace it.
- If the ambient sample (05) has trouble on a particular CNI, the other four
  samples are independent of it and will still work; sample 05 also documents a
  sidecar-based fallback that shows the same gRPC load-balancing point.
- LoadBalancer Services may stay `<pending>` on a playground; the samples do not
  rely on them.

## Cleaning up

```bash
bash setup/uninstall.sh     # remove the samples, apps, and controllers
```

Or just delete the playground cluster.

## License

See [LICENSE](./LICENSE).
