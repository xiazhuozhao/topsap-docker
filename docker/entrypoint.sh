#!/bin/bash
set -Eeuo pipefail

required_files=(
  "${VPN_SERVER_FILE:?}"
  "${VPN_USERNAME_FILE:?}"
  "${VPN_PASSWORD_FILE:?}"
  "${VPN_TOTP_FILE:?}"
)

for secret_file in "${required_files[@]}"; do
  if [[ ! -s "$secret_file" ]]; then
    echo "Required secret is missing or empty: $secret_file" >&2
    exit 2
  fi
done

if [[ ! -c /dev/net/tun ]]; then
  echo "/dev/net/tun is unavailable" >&2
  exit 3
fi

cleanup() {
  jobs -pr | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT INT TERM

cd /opt/TopSAP
./sv_websrv >/var/log/sv_websrv.log 2>&1 &

sleep 2
/usr/local/bin/vpn-login | tee /var/log/topvpn-login.log

for _ in $(seq 1 30); do
  if ip link show tun0 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! ip link show tun0 >/dev/null 2>&1; then
  echo "VPN login did not create tun0" >&2
  tail -n 50 /var/log/sv_websrv.log >&2 || true
  exit 4
fi

ip link set dev tun0 mtu 1300

danted -p /tmp/danted.pid -f /etc/danted.conf &
socat "TCP-LISTEN:10022,reuseaddr,fork" "TCP:${SSH_TARGET:?}:${SSH_TARGET_PORT:-22}" &

echo "VPN is ready: SOCKS5=:1080 SSH-forward=:10022 -> ${SSH_TARGET}:${SSH_TARGET_PORT:-22}"
wait -n
