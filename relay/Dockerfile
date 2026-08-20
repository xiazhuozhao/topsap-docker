FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates gettext-base haproxy openssl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/haproxy/tls \
    && openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
       -subj '/CN=guanli' \
       -keyout /tmp/relay.key -out /tmp/relay.crt \
    && cat /tmp/relay.crt /tmp/relay.key >/etc/haproxy/tls/relay.pem \
    && chmod 0600 /etc/haproxy/tls/relay.pem \
    && rm -f /tmp/relay.key /tmp/relay.crt

COPY haproxy.cfg /etc/haproxy/haproxy.cfg.template
COPY entrypoint.sh /usr/local/bin/relay-entrypoint.sh

RUN chmod 0755 /usr/local/bin/relay-entrypoint.sh

CMD ["/usr/local/bin/relay-entrypoint.sh"]
