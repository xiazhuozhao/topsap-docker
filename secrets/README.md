# VPN secrets directory

Create the following files locally before starting the Compose project. Each file must contain exactly one value, without committing the values to Git:

```text
vpn_username
vpn_password
vpn_totp
```

Protect the files with restrictive permissions:

```bash
chmod 600 secrets/vpn_username secrets/vpn_password secrets/vpn_totp
```

These files authenticate only the VPN client; they are not SSH target credentials. This directory is intentionally ignored by Git. Never publish VPN passwords, TOTP seeds, or other authentication material in the repository, container image, logs, or issue reports.
