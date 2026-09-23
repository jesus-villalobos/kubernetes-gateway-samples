# Shared helpers for the Gateway API samples.
# Source from every script:  . "$(dirname "$0")/../lib/common.sh"
# Single cluster; samples are separated by namespace, not by kube-context.
# The helpers print each command before running it so the sample doubles as a
# readable, self-documenting tutorial.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "${REPO_ROOT}/versions.env"

# AUTO=1 disables interactive pauses (used for unattended/recorded runs).
AUTO="${AUTO:-0}"

_BOLD=$'\033[1m'; _DIM=$'\033[2m'; _CYAN=$'\033[36m'; _GRN=$'\033[32m'
_YEL=$'\033[33m'; _RED=$'\033[31m'; _RST=$'\033[0m'

hr() { printf '%s\n' "----------------------------------------------------------------------"; }
banner() { echo; hr; printf '%s\n' "${_BOLD}${_CYAN}$*${_RST}"; hr; }
say() { printf '%s\n' "${_DIM}# $*${_RST}"; }
step() { printf '%s\n' "${_YEL}STEP $*${_RST}"; }
run() { printf '%s\n' "${_GRN}\$ $*${_RST}"; eval "$@"; }
expect() { printf '%s\n' "${_DIM}EXPECT: $*${_RST}"; }
ok()   { printf '%s\n' "${_GRN}OK: $*${_RST}"; }
warn() { printf '%s\n' "${_YEL}WARN: $*${_RST}"; }
fail() { printf '%s\n' "${_RED}FAIL: $*${_RST}"; }

pause() {
  [ "${AUTO}" = "1" ] && { sleep "${AUTO_DELAY:-2}"; return; }
  printf '%s' "${_DIM}(press Enter to continue)${_RST}"
  read -r _ || true
}

wait_rollout() { local ns="$1"; shift; run "kubectl -n ${ns} rollout status $* --timeout=180s"; }
wait_gateway() { run "kubectl -n $1 wait --for=condition=Programmed gateway/$2 --timeout=180s"; }
wait_route()   { run "kubectl -n $1 wait --for=condition=Accepted httproute/$2 --timeout=60s"; }

# Background port-forward to a Service; waits until the local port answers.
# Usage: pfwd <ns> <svc> <localport> <remoteport>
_PFWD_PIDS=()
pfwd() {
  local ns="$1" svc="$2" lport="$3" rport="$4" i
  run "kubectl -n ${ns} port-forward svc/${svc} ${lport}:${rport} >/tmp/pfwd-${lport}.log 2>&1 &"
  _PFWD_PIDS+=("$!")
  for i in $(seq 1 30); do
    curl -s -o /dev/null "http://127.0.0.1:${lport}" 2>/dev/null && break
    sleep 0.5
  done
  say "port-forward ready on 127.0.0.1:${lport} -> ${svc}.${ns}:${rport}"
}

# Port-forward to the first Service matching a label selector (for controllers
# that name the gateway Service with a hash, e.g. Envoy Gateway).
pfwd_label() {
  local ns="$1" sel="$2" lport="$3" rport="$4" svc
  svc=$(kubectl -n "${ns}" get svc -l "${sel}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  [ -z "${svc}" ] && { fail "no service in ${ns} matching ${sel}"; return 1; }
  pfwd "${ns}" "${svc}" "${lport}" "${rport}"
}

pfwd_stop() {
  local pid
  for pid in "${_PFWD_PIDS[@]:-}"; do [ -n "${pid}" ] && kill "${pid}" 2>/dev/null || true; done
  _PFWD_PIDS=()
  pkill -f "kubectl.*port-forward" 2>/dev/null || true
}
trap 'pfwd_stop' EXIT

# Fire N requests, print a compact OK/-- marker line, and tally status codes.
# Usage: burst <count> <local-port> <path> [extra curl args...]
burst() {
  local n="$1" port="$2" path="$3"; shift 3
  local marks="" code ok2=0 rl=0 other=0 i
  for i in $(seq 1 "$n"); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -H "Host: ${DEMO_HOST}" "$@" "http://127.0.0.1:${port}${path}" || echo 000)
    case "$code" in
      200) marks="${marks}OK "; ok2=$((ok2+1)) ;;
      429) marks="${marks}-- "; rl=$((rl+1)) ;;
      *)   marks="${marks}${code} "; other=$((other+1)) ;;
    esac
  done
  printf '%s\n' "$marks"
  printf '%s\n' "${_DIM}tally: 200=${ok2}  429=${rl}  other=${other}${_RST}"
}
