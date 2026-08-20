FROM debian:bullseye-slim

ARG TOPSAP_DEB=packages/TopSAP-3.5.2.36.2-x86_64.deb

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/gateway

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates cron dante-server iproute2 iptables \
       procps psmisc python3 socat sudo tzdata \
    && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo Asia/Shanghai >/etc/timezone \
    && echo Ubuntu >>/etc/issue \
    && rm -rf /var/lib/apt/lists/*

COPY ${TOPSAP_DEB} /tmp/topsap.deb
RUN dpkg -i /tmp/topsap.deb \
    && rm -f /tmp/topsap.deb

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/totp.py /usr/local/bin/totp
COPY docker/vpn_login.py /usr/local/bin/vpn-login
COPY docker/danted.conf /etc/danted.conf

RUN chmod 0755 /usr/local/bin/entrypoint.sh /usr/local/bin/totp /usr/local/bin/vpn-login \
    && chmod 0644 /etc/danted.conf

EXPOSE 1080 10022

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
