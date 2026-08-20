#!/usr/bin/env python3
"""Log in through TopSAP's local API, including legacy Google-TOTP support."""

import base64
import json
import os
import ssl
import subprocess
import time
import urllib.request


API_ROOT = "https://127.0.0.1:7443/api/v1/"
SSL_CONTEXT = ssl._create_unverified_context()


def read_secret(env_name: str) -> str:
    with open(os.environ[env_name], "r", encoding="utf-8") as secret_file:
        return secret_file.read().strip()


def post(endpoint: str, body: dict) -> dict:
    request = urllib.request.Request(
        API_ROOT + endpoint,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, context=SSL_CONTEXT, timeout=45) as response:
        return json.loads(response.read())


def encoded(value: str) -> str:
    return base64.b64encode(value.encode("utf-8")).decode("ascii")


def main() -> int:
    username = read_secret("VPN_USERNAME_FILE")
    password = read_secret("VPN_PASSWORD_FILE")
    address = os.environ["VPN_CONNECT_ADDRESS"]
    host, port = address.rsplit(":", 1)

    common = {
        "proxy": {"type": "", "addr": "", "port": "", "user": "", "pwd": "", "domain": ""},
        "vpn_version": "ngvone",
        "auth_protocol": "0",
        "auth_port": "443",
        "data_port": "443",
        "data_protocol": "0",
        "cert_type": "0",
    }
    login_body = {
        **common,
        "method": "login_by_pwd",
        "vone": {
            "addr": host,
            "port": port,
            "user": encoded(username),
            "pwd": encoded(password),
        },
        "remember_pwd": "off",
    }

    # sv_websrv needs a moment after accepting TCP before its API is ready.
    for attempt in range(20):
        try:
            result = post("login_by_pwd", login_body)
            break
        except Exception:
            if attempt == 19:
                raise
            time.sleep(0.5)

    code = int(result.get("err_code", -1))
    if code in (-40192, -40039, -40200):
        token = subprocess.check_output(
            ["/usr/local/bin/totp", os.environ["VPN_TOTP_FILE"]], text=True
        ).strip()
        # TopSAP 3.5.2 requires flag=otp to distinguish TOTP from SMS.
        result = post("chk_sms", {"method": "chk_sms", "sms": token, "flag": "otp"})
        code = int(result.get("err_code", -1))

    if code == -40077 and os.environ.get("VPN_KICK_EXISTING") == "yes":
        kick_body = dict(login_body)
        kick_body["method"] = "kick_user"
        result = post("kick_user", kick_body)
        code = int(result.get("err_code", -1))

    if code != 0:
        raise RuntimeError(f"VPN login failed with error code {code}")

    print("VPN authentication succeeded")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
