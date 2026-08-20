#!/usr/bin/env python3
"""Generate a six-digit RFC 6238 TOTP without exposing the seed in argv."""

import base64
import hashlib
import hmac
import struct
import sys
import time


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: totp SECRET_FILE", file=sys.stderr)
        return 2

    with open(sys.argv[1], "r", encoding="ascii") as secret_file:
        encoded = "".join(secret_file.read().split()).upper()

    encoded += "=" * ((8 - len(encoded) % 8) % 8)
    key = base64.b32decode(encoded, casefold=True)
    counter = int(time.time()) // 30
    digest = hmac.new(key, struct.pack(">Q", counter), hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    token = (struct.unpack(">I", digest[offset : offset + 4])[0] & 0x7FFFFFFF) % 1_000_000
    print(f"{token:06d}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

