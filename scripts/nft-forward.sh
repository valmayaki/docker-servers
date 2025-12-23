#!/usr/bin/env bash
set -euo pipefail

########################################
# nft-forward
# Production nftables port-forward manager
########################################

CONFIG_FILE="/etc/nft-forward.conf"

ACTION="${1:-}"
shift || true

# -------------------------
# Globals / defaults
# -------------------------
PROTO=""
HOST_PORT=""
DEST_IP=""
DEST_PORT=""
IFACE=""
LAN_ONLY="false"
SERVICE=""

LAN_SUBNET="auto"
DEFAULT_IFACE="auto"

[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# -------------------------
# Usage
# -------------------------
usage() {
cat <<EOF
Usage:
  nft-forward add|delete|list|status|persist|rollback|diff|validate|doctor|systemd-setup

Add/Delete options:
  --proto tcp|udp|both
  --host-port <port>
  --dest-ip <ip>
  --dest-port <port>
  --iface <iface>
  --lan-only
  --service pihole|portainer

Other:
  rollback <timestamp>

Examples:
  nft-forward add --service pihole
  nft-forward add --proto tcp --host-port 9443 --dest-ip 192.168.3.4 --dest-port 9443 --lan-only
  nft-forward persist
  nft-forward doctor
EOF
exit 1
}

# -------------------------
# Argument parsing
# -------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --proto) PROTO="$2"; shift 2 ;;
    --host-port) HOST_PORT="$2"; shift 2 ;;
    --dest-ip) DEST_IP="$2"; shift 2 ;;
    --dest-port) DEST_PORT="$2"; shift 2 ;;
    --iface) IFACE="$2"; shift 2 ;;
    --lan-only) LAN_ONLY="true"; shift ;;
    --service) SERVICE="$2"; shift 2 ;;
    *) break ;;
  esac
done

# -------------------------
# Detection / helpers
# -------------------------
detect_lan() {
  ip route | awk '/default/ {print $3}' | xargs -I{} ip route | awk '/src/ {print $1; exit}'
}

select_iface() {
  if [[ ! -t 0 ]]; then
    echo "✖ Non-interactive mode: --iface must be specified"
    exit 1
  fi
  mapfile -t IFACES < <(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
  echo "Select interface:"
  select IFACE in "${IFACES[@]}"; do
    [[ -n "$IFACE" ]] && break
  done
}

detect_firewall_backend() {
  if ! command -v nft >/dev/null 2>&1; then
    echo "✖ nft command not found"
    exit 1
  fi
  if ! nft list ruleset >/dev/null 2>&1; then
    echo "✖ nftables not usable (permission denied or kernel module missing)"
    exit 1
  fi
}

# -------------------------
# nftables primitives
# -------------------------
ensure_nft() {
  nft list table ip nat >/dev/null 2>&1 || nft add table ip nat
  nft list table ip filter >/dev/null 2>&1 || nft add table ip filter

  nft list chain ip nat prerouting >/dev/null 2>&1 || \
    nft add chain ip nat prerouting { type nat hook prerouting priority 0 \; }

  nft list chain ip filter forward >/dev/null 2>&1 || \
    nft add chain ip filter forward { type filter hook forward priority 0 \; }
}

add_rule() { nft list ruleset | grep -F "$1" >/dev/null || nft add rule "$1"; }
del_rule() { nft list ruleset | grep -F "$1" >/dev/null && nft delete rule "$1"; }

# -------------------------
# Presets
# -------------------------
apply_service() {
  case "$SERVICE" in
    pihole)
      PROTO="both"
      HOST_PORT=53
      DEST_PORT=53
      DEST_IP="${PIHOLE_IP:-}"
      LAN_ONLY="true"
      ;;
    portainer)
      PROTO="tcp"
      HOST_PORT=9443
      DEST_PORT=9443
      DEST_IP="${PORTAINER_IP:-}"
      LAN_ONLY="true"
      ;;
    *)
      echo "Unknown service preset"
      exit 1
      ;;
  esac
}

# -------------------------
# Rule application
# -------------------------
apply_proto() {
  local P="$1"
  local SRC=""

  [[ "$LAN_ONLY" == "true" ]] && SRC="ip saddr $LAN_SUBNET"

  add_rule "ip nat prerouting iifname \"$IFACE\" $SRC $P dport $HOST_PORT dnat to $DEST_IP:$DEST_PORT comment \"nft-forward\""
  add_rule "ip filter forward $SRC $P dport $DEST_PORT ip daddr $DEST_IP ct state new,established accept comment \"nft-forward\""
  add_rule "ip filter forward $P sport $DEST_PORT ip saddr $DEST_IP ct state established accept comment \"nft-forward\""
}

delete_proto() {
  local P="$1"

  del_rule "ip nat prerouting iifname \"$IFACE\" $P dport $HOST_PORT dnat to $DEST_IP:$DEST_PORT comment \"nft-forward\""
  del_rule "ip filter forward $P dport $DEST_PORT ip daddr $DEST_IP ct state new,established accept comment \"nft-forward\""
  del_rule "ip filter forward $P sport $DEST_PORT ip saddr $DEST_IP ct state established accept comment \"nft-forward\""
}

# -------------------------
# Persistence
# -------------------------
persist_rules() {
  local CONF="/etc/nftables.conf"
  local BK="/etc/nftables.backups"
  local TS="$(date +%Y%m%d-%H%M%S)"

  mkdir -p "$BK"
  nft list ruleset > "$CONF.tmp"
  nft -c -f "$CONF.tmp" || { rm -f "$CONF.tmp"; exit 1; }

  [[ -f "$CONF" ]] && cp "$CONF" "$BK/nftables-$TS.conf"
  mv "$CONF.tmp" "$CONF"

  systemctl reload nft-forward || systemctl restart nft-forward
  echo "✔ Rules persisted ($TS)"
}

rollback_rules() {
  local TS="${1:-}"
  [[ -z "$TS" ]] && { echo "Timestamp required"; exit 1; }
  nft -f "/etc/nftables.backups/nftables-$TS.conf"
  echo "✔ Rolled back to $TS"
}

# -------------------------
# systemd setup
# -------------------------
systemd_setup() {
cat <<EOF >/etc/systemd/system/nft-forward.service
[Unit]
Description=Custom nftables Port Forwards
After=network-pre.target
Before=network.target
Requires=nftables.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/nft -f /etc/nftables.conf
ExecReload=/usr/sbin/nft -f /etc/nftables.conf
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable nft-forward
  echo "✔ systemd service installed"
}

# -------------------------
# Doctor
# -------------------------
doctor() {
  echo "▶ nft-forward doctor"
  echo
  uname -r
  echo
  [[ -f /etc/os-release ]] && . /etc/os-release && echo "$PRETTY_NAME"
  echo
  command -v nft >/dev/null && echo "✔ nft installed" || echo "✖ nft missing"
  command -v iptables >/dev/null && echo "✔ iptables installed" || echo "✖ iptables missing"
  echo
  nft list ruleset >/dev/null 2>&1 && echo "✔ nftables usable" || echo "✖ nftables not usable"
}

# -------------------------
# Main
# -------------------------
[[ -z "$ACTION" ]] && usage

detect_firewall_backend

[[ "$LAN_SUBNET" == "auto" ]] && LAN_SUBNET="$(detect_lan)"
[[ "$IFACE" == "auto" || -z "$IFACE" ]] && select_iface

case "$ACTION" in
  add|delete)
    ensure_nft
    [[ -n "$SERVICE" ]] && apply_service
    [[ -z "$PROTO" || -z "$HOST_PORT" || -z "$DEST_IP" || -z "$DEST_PORT" ]] && usage

    for P in ${PROTO/both/"tcp udp"}; do
      [[ "$ACTION" == "add" ]] && apply_proto "$P"
      [[ "$ACTION" == "delete" ]] && delete_proto "$P"
    done
    ;;
  list)
    nft list table ip nat
    ;;
  status)
    nft list ruleset
    ;;
  persist)
    persist_rules
    ;;
  rollback)
    rollback_rules "${1:-}"
    ;;
  diff)
    diff -u /etc/nftables.conf <(nft list ruleset) || true
    ;;
  validate)
    nft -c -f /etc/nftables.conf
    ;;
  doctor)
    doctor
    ;;
  systemd-setup)
    systemd_setup
    ;;
  *)
    usage
    ;;
esac
