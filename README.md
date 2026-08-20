# topsap-docker

TopSAP VPN gateway for Linux and WSL2

English | [中文](#中文说明)

## Overview

This project packages the Topsec TopSAP VPN client in a Docker container so Linux users can connect when a newer client release is not published for Linux. The tested client package is **TopSAP 3.5.2.36.2 for x86_64**.

The container provides:

- A local SOCKS5 proxy for arbitrary VPN-reachable TCP services.
- An optional fixed TCP forward for one SSH target.
- Automated Google Authenticator/TOTP login.
- A TLS compatibility relay for VPN gateways that require TLS 1.3.

### Why a TLS relay is needed

The current latest VPN gateway, corresponding to the TopSAP **3.6.5.19.64.1** client, uses **TLS 1.3**, while the available TopSAP Linux client (3.5.2.36.2) initiates its VPN connection with the older **TLS 1.2** protocol. Newer TopSAP releases may also be available for other platforms before a Linux package is published. `topsap-docker` runs the usable Linux client alongside HAProxy: the relay accepts the client's TLS 1.2 connection and creates a separate TLS 1.3 connection to the VPN gateway. It is a protocol compatibility layer; it does not replace VPN authentication.

This project is a reusable deployment pattern, not a replacement for or redistribution of the vendor client. It does not include the proprietary TopSAP package, VPN credentials, or any VPN service access.

## Requirements

- Docker Engine with Docker Compose v2.
- Linux x86_64 or WSL2 with Docker support.
- `/dev/net/tun` available on the host.
- A legally obtained TopSAP Linux `.deb` package.
- Authorization to use the target VPN service and its credentials.

Put the package in `packages/`. By default, the build expects `packages/TopSAP-3.5.2.36.2-x86_64.deb`. This path is configurable through `TOPSAP_DEB` in `.env`. Do not commit or redistribute the package without explicit permission from Topsec.

## Configuration

Create the VPN login secret files below, one value per file, and protect them with mode `0600`:

```text
secrets/vpn_username
secrets/vpn_password
secrets/vpn_totp
```

`vpn_username`, `vpn_password`, and `vpn_totp` are used only to authenticate the TopSAP VPN client. They are not SSH credentials. The SSH username, password, and keys remain entirely in your SSH client and on the SSH target.

Copy the configuration template and edit it for your environment:

```bash
cp .env.example .env
```

```dotenv
# TopSAP package used while building the image.
TOPSAP_DEB=packages/TopSAP-3.5.2.36.2-x86_64.deb

# Public VPN gateway and the internal TLS relay port.
VPN_GATEWAY_HOST=vpn.example.org
VPN_GATEWAY_PORT=44443
VPN_RELAY_PORT=44443
VPN_KICK_EXISTING=no

# Local-only SOCKS5 proxy port.
SOCKS_HOST_PORT=1088

# One SSH target reachable after VPN login.
SSH_TARGET=VPN_TARGET_IP
SSH_TARGET_PORT=22
SSH_FORWARD_LISTEN_PORT=10022
SSH_FORWARD_HOST_PORT=10022
SSH_FORWARD_BIND_ADDRESS=127.0.0.1
```

`VPN_GATEWAY_PORT` is the public TLS port of the VPN gateway. `VPN_RELAY_PORT` is used only between the two Compose services and can normally remain the same. `SSH_FORWARD_LISTEN_PORT` is the container-side listener, while `SSH_FORWARD_HOST_PORT` is the host port used by SSH clients. Set `VPN_KICK_EXISTING=yes` only when the VPN policy permits disconnecting an existing session.

## Start and use

```bash
docker compose up -d --build
docker compose logs -f
docker compose ps
```

Use the fixed SSH forward with the SSH account of the target host:

```bash
ssh -p 10022 SSH_USER@127.0.0.1
```

Use the SOCKS5 proxy for another VPN resource:

```bash
ssh -o 'ProxyCommand=nc -X 5 -x 127.0.0.1:1088 %h %p' SSH_USER@VPN_RESOURCE
```

To stop the gateway:

```bash
docker compose down
```

## Ports and access model

| Endpoint | Default | Use |
| --- | --- | --- |
| SOCKS5 proxy | `127.0.0.1:1088` | Reaches arbitrary TCP services available through the VPN. Use it for multiple internal hosts with a SOCKS-aware client or `ProxyCommand`. It is always local-only. |
| Fixed SSH forward | `127.0.0.1:10022` | Reaches only `SSH_TARGET:SSH_TARGET_PORT`. Use it for one simple SSH destination without SOCKS configuration. The SSH username is `SSH_USER`, not `vpn_username`. |

To allow trusted remote machines to use the fixed SSH forward, set `SSH_FORWARD_BIND_ADDRESS=0.0.0.0` and restrict the port with a host firewall. The SOCKS5 proxy intentionally cannot be exposed through this configuration. For WSL2 default NAT networking, run `windows-expose.ps1` from an Administrator PowerShell to refresh the Windows port forward after the WSL IP changes. Its `-ListenPort` parameter is the Windows port and `-WslPort` must match `SSH_FORWARD_HOST_PORT`.

## Security and operational notes

- Never place VPN passwords or TOTP seeds in Git, images, logs, or issue reports.
- Treat the TOTP seed as a password and rotate it if disclosed.
- Do not expose the fixed SSH forward without a firewall rule limiting access to trusted sources.
- The TLS relay uses `verify none` to work with the tested gateway. Review this policy against your VPN provider's certificate requirements before production use.
- This repository has been tested with TopSAP 3.5.2.36.2; newer packages may need changes to the login automation or relay settings.

## Copyright, trademarks, and license

TopSAP, Topsec, and related names and logos are trademarks or property of 天融信 (Topsec). This project is an independent community integration and is not sponsored, endorsed, or maintained by Topsec. All rights to the TopSAP software remain with their respective copyright holders. Users are responsible for obtaining the client lawfully and complying with their VPN provider's terms, licenses, and security policies.

The original code and configuration in this repository are licensed under the [MIT License](LICENSE). This license does not grant rights to the proprietary TopSAP software, vendor packages, trademarks, VPN credentials, or VPN services.

## 中文说明

### 项目简介

本项目将天融信 TopSAP VPN 客户端运行在 Docker 容器中，使 Linux 用户在新版本客户端尚未发布 Linux 版本时仍可使用 VPN 服务。当前验证的客户端版本为 **TopSAP 3.5.2.36.2（x86_64）**。

容器提供：

- 本机 SOCKS5 代理，可访问任意 VPN 内的 TCP 服务。
- 可选的固定 TCP 转发，仅转发到一个 SSH 目标。
- Google Authenticator/TOTP 动态验证码自动登录。
- 用于兼容 TLS 1.3 VPN 网关的 TLS 中继。

### 为什么需要 TLS 中继

当前最新 VPN 网关（对应 TopSAP **3.6.5.19.64.1** 客户端）使用 **TLS 1.3**，而可用的 TopSAP Linux 客户端（3.5.2.36.2）发起 VPN 连接时仍使用较旧的 **TLS 1.2**。同时，新版 TopSAP 可能已经在其他平台发布而 Linux 安装包尚未提供。`topsap-docker` 将可用的 Linux 客户端和 HAProxy 一同运行：中继接收客户端的 TLS 1.2 连接，再单独向 VPN 网关建立 TLS 1.3 连接。它只是协议兼容层，不替代 VPN 认证。

本项目是可复用的部署方案，不重新发布或替代厂商客户端。仓库不包含 TopSAP 专有安装包、VPN 凭据或任何 VPN 服务访问权限。

### 环境要求

- Docker Engine 和 Docker Compose v2。
- x86_64 Linux 或支持 Docker 的 WSL2。
- 主机存在 `/dev/net/tun`。
- 合法取得的 TopSAP Linux `.deb` 安装包。
- 使用目标 VPN 服务及其账号的授权。

将安装包放入 `packages/`。默认构建路径为 `packages/TopSAP-3.5.2.36.2-x86_64.deb`，也可以在 `.env` 中通过 `TOPSAP_DEB` 修改。未经天融信明确授权，请勿提交或重新发布该安装包。

### 配置

在 `secrets/` 中创建以下 VPN 登录信息文件，每个文件只放一个值，并设置权限为 `0600`：

```text
secrets/vpn_username
secrets/vpn_password
secrets/vpn_totp
```

`vpn_username`、`vpn_password` 和 `vpn_totp` 仅用于登录 TopSAP VPN，并不是 SSH 目标机的登录凭据。SSH 用户名、密码和密钥始终由 SSH 客户端及目标主机处理。

复制配置模板并按实际环境修改：

```bash
cp .env.example .env
```

```dotenv
# 构建镜像时使用的 TopSAP 安装包。
TOPSAP_DEB=packages/TopSAP-3.5.2.36.2-x86_64.deb

# 公网 VPN 网关及内部 TLS 中继端口。
VPN_GATEWAY_HOST=vpn.example.org
VPN_GATEWAY_PORT=44443
VPN_RELAY_PORT=44443
VPN_KICK_EXISTING=no

# 仅本机可访问的 SOCKS5 端口。
SOCKS_HOST_PORT=1088

# VPN 登录后可访问的一个 SSH 目标。
SSH_TARGET=VPN_TARGET_IP
SSH_TARGET_PORT=22
SSH_FORWARD_LISTEN_PORT=10022
SSH_FORWARD_HOST_PORT=10022
SSH_FORWARD_BIND_ADDRESS=127.0.0.1
```

`VPN_GATEWAY_PORT` 是公网 VPN 网关的 TLS 端口；`VPN_RELAY_PORT` 只在两个 Compose 服务之间使用，通常保持相同即可。`SSH_FORWARD_LISTEN_PORT` 是容器内监听端口，`SSH_FORWARD_HOST_PORT` 是 SSH 客户端实际连接的本机端口。只有在 VPN 策略允许断开既有会话时，才将 `VPN_KICK_EXISTING` 设为 `yes`。

### 启动和使用

```bash
docker compose up -d --build
docker compose logs -f
docker compose ps
```

使用目标机自己的 SSH 账号连接固定转发：

```bash
ssh -p 10022 SSH_USER@127.0.0.1
```

通过 SOCKS5 访问其他 VPN 资源：

```bash
ssh -o 'ProxyCommand=nc -X 5 -x 127.0.0.1:1088 %h %p' SSH_USER@VPN_RESOURCE
```

停止网关：

```bash
docker compose down
```

### 端口与访问方式

| 端点 | 默认值 | 用途 |
| --- | --- | --- |
| SOCKS5 代理 | `127.0.0.1:1088` | 可访问 VPN 内任意 TCP 服务。适合通过 SOCKS5 客户端或 `ProxyCommand` 访问多个内部主机，始终只监听本机。 |
| 固定 SSH 转发 | `127.0.0.1:10022` | 仅访问 `SSH_TARGET:SSH_TARGET_PORT`。适合不希望配置 SOCKS5 的单一 SSH 目标；使用的账号是 `SSH_USER`，不是 `vpn_username`。 |

如需让可信远程机器访问固定 SSH 转发，请将 `SSH_FORWARD_BIND_ADDRESS` 改为 `0.0.0.0`，并用主机防火墙限制来源。SOCKS5 代理不会通过本项目配置暴露到远程网络。WSL2 默认 NAT 网络下，可在管理员 PowerShell 中运行 `windows-expose.ps1`，在 WSL IP 变化后刷新 Windows 端口转发；其 `-ListenPort` 是 Windows 端口，`-WslPort` 必须与 `SSH_FORWARD_HOST_PORT` 一致。

### 安全、版权和许可证

- 不要把 VPN 密码或 TOTP 密钥写入 Git、镜像、日志或 Issue；TOTP 密钥泄露后应按密码泄露处理并及时更换。
- 不要在缺少防火墙来源限制的情况下暴露固定 SSH 转发。
- TLS 中继为适配已验证的网关而使用 `verify none`。生产使用前，请根据 VPN 服务商的证书要求审查该策略。
- 本项目已验证 TopSAP 3.5.2.36.2；新版客户端可能需要调整登录自动化或中继设置。

TopSAP、Topsec 及相关名称和标识属于天融信（Topsec）或其相应权利人。本项目为独立的社区集成项目，与天融信无赞助、背书或维护关系。TopSAP 软件的全部版权和许可权利仍归原权利人所有。用户应合法获取客户端，并遵守 VPN 服务商的许可、使用条款和安全政策。

本仓库原创代码和配置采用 [MIT License](LICENSE) 发布。该许可证不授予 TopSAP 专有软件、厂商安装包、商标、VPN 凭据或 VPN 服务的使用权利。
