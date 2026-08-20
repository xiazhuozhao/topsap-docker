#!/bin/sh
set -eu

: "${VPN_GATEWAY_HOST:?Set VPN_GATEWAY_HOST to the VPN gateway hostname or address}"
: "${VPN_GATEWAY_PORT:?Set VPN_GATEWAY_PORT to the VPN gateway TLS port}"
: "${VPN_RELAY_PORT:?Set VPN_RELAY_PORT to the relay listener port}"

export VPN_GATEWAY_HOST VPN_GATEWAY_PORT VPN_RELAY_PORT
envsubst '${VPN_GATEWAY_HOST} ${VPN_GATEWAY_PORT} ${VPN_RELAY_PORT}' \
  < /etc/haproxy/haproxy.cfg.template \
  > /etc/haproxy/haproxy.cfg

exec haproxy -W -db -f /etc/haproxy/haproxy.cfg
