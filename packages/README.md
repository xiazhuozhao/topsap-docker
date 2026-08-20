# TopSAP package directory

Place the legally obtained TopSAP Linux package in this directory before building the image:

```text
TopSAP-3.5.2.36.2-x86_64.deb
```

The package is proprietary and is intentionally excluded from Git by the repository's `.gitignore`. Do not commit or redistribute it without the copyright holder's permission. To use a different package name, set `TOPSAP_DEB` in `.env`.
