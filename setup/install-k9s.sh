#!/usr/bin/env bash
# Install k9s, a terminal UI for Kubernetes, used as the optional visual pane
# alongside the samples (watch Gateways/Routes reconcile and tail gateway logs).
# This installs a local tool; it does not touch the cluster.
. "$(dirname "$0")/../lib/common.sh"

banner "Installing k9s (via webi)"
run "curl -sS https://webi.sh/k9s | sh"
# webi puts binaries on PATH via this env file for the current shell.
run "source ~/.config/envman/PATH.env 2>/dev/null || true"

if command -v k9s >/dev/null 2>&1; then
  ok "k9s installed: $(k9s version --short 2>/dev/null | head -1)"
else
  warn "k9s installed, but not on PATH in this shell yet"
  say "run:  source ~/.config/envman/PATH.env   (or open a new shell)"
fi

say "use the repo's k9s aliases with:  export K9S_CONFIG_DIR=\"\$PWD/k9s\"  then  k9s"
