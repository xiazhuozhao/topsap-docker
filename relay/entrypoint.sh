#!/bin/sh
set -eu

: "${VPN_GATEWAY_HOST:?Set VPN_GATEWAY_HOST to the VPN gateway hostname or address}"
: "${VPN_GATEWAY_PORT:=44443}"

export VPN_GATEWAY_HOST VPN_GATEWAY_PORT
envsubst '${VPN_GATEWAY_HOST} ${VPN_GATEWAY_PORT}' \
  < /etc/haproxy/haproxy.cfg.template \
  > /etc/haproxy/haproxy.cfg

exec haproxy -W -db -f /etc/haproxy/haproxy.cfg
