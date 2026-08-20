# topsap-docker

TopSAP VPN gateway for Linux and WSL2

English | [中文](#中文说明)

## Overview

This project packages the Topsec TopSAP VPN client in a Docker container so Linux users can connect to a TopSAP VPN service when a newer client release is not published for Linux. The tested client package is **TopSAP 3.5.2.36.2 for x86_64**.

The container provides:

- a local SOCKS5 proxy at `127.0.0.1:1088` for reaching VPN resources;
- an optional TCP forward on port `10022` for one configured SSH target;
- automatic Google Authenticator/TOTP login;
- a small TLS compatibility relay for VPN gateways that require modern TLS.

### Why a TLS relay is needed

The current VPN gateway uses **TLS 1.3**, while the available TopSAP Linux client (3.5.2.36.2) still initiates its VPN connection with the older **TLS 1.2** protocol. In addition, newer TopSAP releases may be available for other platforms before a Linux package is published. `topsap-docker` keeps the working Linux client inside the container and places an HAProxy relay beside it: the relay accepts the client's TLS 1.2 connection and creates a separate TLS 1.3 connection to the VPN gateway. This is a protocol compatibility layer; it does not decrypt or replace the VPN authentication flow.

The project is intended as a reusable deployment pattern, not as a replacement for or redistribution of the vendor client. It does not include the proprietary TopSAP package, VPN credentials, or any VPN service access.

## Architecture

The TopSAP client runs with a TUN device inside the `topsap` container. A separate HAProxy container accepts the legacy TLS connection required by the client and re-encrypts it for the VPN gateway. Dante exposes the authenticated VPN network as a SOCKS5 proxy. The fixed TCP forward is limited to the SSH target configured in `compose.yaml`.

## Requirements

- Docker Engine with Docker Compose v2;
- Linux x86_64 or WSL2 with Docker support;
- `/dev/net/tun` available on the host;
- a legally obtained TopSAP Linux `.deb` package;
- permission to use the target VPN service and its credentials.

The image currently expects:

```text
packages/TopSAP-3.5.2.36.2-x86_64.deb
```

Do not commit this package unless you have explicit permission from Topsec. For another client version, update `ARG TOPSAP_DEB` in `Dockerfile` and verify the login flow before deploying it.

## Configuration

Create the secret files below, one value per file, and protect them with mode `0600`:

```text
secrets/vpn_server
secrets/vpn_username
secrets/vpn_password
secrets/vpn_totp
```

Copy `.env.example` to `.env` and set the VPN gateway and target values:

```bash
cp .env.example .env
```

Then edit `.env`:

```dotenv
VPN_GATEWAY_HOST=vpn.example.org
VPN_GATEWAY_PORT=44443
SSH_TARGET=VPN_TARGET_IP
SSH_TARGET_PORT=22
```

The default setup kicks an existing VPN session when logging in. Change `VPN_KICK_EXISTING` only if the VPN administrator permits concurrent sessions.

## Start and use

```bash
docker compose up -d --build
docker compose logs -f
docker compose ps
```

Use the fixed SSH target:

```bash
ssh -p 10022 VPN_USER@127.0.0.1
```

Use the SOCKS5 proxy for another VPN resource:

```bash
ssh -o 'ProxyCommand=nc -X 5 -x 127.0.0.1:1088 %h %p' user@VPN_RESOURCE
```

To stop the gateway:

```bash
docker compose down
```

The SOCKS5 port is local-only by design. Port `10022` is published on the host interfaces because it is intended for a single, explicitly configured SSH target. Restrict it with your host firewall and expose it to other machines only when necessary.

For WSL2's default NAT networking, run `windows-expose.ps1` from an Administrator PowerShell to refresh a Windows port-forward after the WSL IP changes. Review the script and firewall scope before using it in production.

## Security and operational notes

- Never place VPN passwords or TOTP seeds in Git, images, logs, or issue reports.
- Treat the TOTP seed as a password; rotate it if it is disclosed.
- Do not expose the SOCKS5 listener to an untrusted network.
- The TLS relay is a compatibility component. Confirm that its endpoint and certificate policy match your VPN provider's requirements.
- This repository has been tested with TopSAP 3.5.2.36.2; newer packages may need changes to the login automation or relay settings.

## Copyright and trademark notice

TopSAP, Topsec, and related names and logos are trademarks or property of 天融信 (Topsec). This project is an independent community integration and is not sponsored, endorsed, or maintained by Topsec. All rights to the TopSAP software remain with their respective copyright holders. Users are responsible for obtaining the client lawfully and complying with their VPN provider's terms, licenses, and security policies.

## License

The original code and configuration in this repository are licensed under the [MIT License](LICENSE). This license does not grant rights to the proprietary TopSAP software, vendor packages, trademarks, VPN credentials, or VPN services.

## 中文说明

### 项目简介

本项目将天融信 TopSAP VPN 客户端运行在 Docker 容器中，使 Linux 用户在新版本客户端没有发布 Linux 版本时，也能够使用较新的 VPN 服务。当前已验证的客户端版本为 **TopSAP 3.5.2.36.2（x86_64）**。

容器提供：

- 本机 SOCKS5 代理 `127.0.0.1:1088`，用于访问 VPN 内部资源；
- 可选的 `10022` TCP 转发，仅转发到 `compose.yaml` 中配置的 SSH 目标；
- Google Authenticator/TOTP 动态验证码登录；
- TLS 兼容中继，用于适配客户端与 VPN 网关之间的 TLS 版本差异。

### 为什么需要 TLS 中继

当前 VPN 网关使用 **TLS 1.3**，而目前可用的 TopSAP Linux 客户端（3.5.2.36.2）发起 VPN 连接时仍使用较旧的 **TLS 1.2**。同时，其他平台可能已经发布了更新版本，而 Linux 版本尚未同步提供。`topsap-docker` 将可用的 Linux 客户端保留在容器中，并在旁边运行 HAProxy 中继：中继接收客户端的 TLS 1.2 连接，再单独向 VPN 网关建立 TLS 1.3 连接。它只是协议兼容层，不解密或替代 VPN 的认证流程。

本项目是可复用的部署方案，不重新发布或替代厂商客户端。仓库不包含 TopSAP 专有安装包、VPN 账号密码或任何 VPN 服务访问权限。

### 环境要求

- Docker Engine 和 Docker Compose v2；
- x86_64 Linux 或支持 Docker 的 WSL2；
- 主机存在 `/dev/net/tun`；
- 合法取得的 TopSAP Linux `.deb` 安装包；
- 使用目标 VPN 服务及其账号的授权。

将安装包放到：

```text
packages/TopSAP-3.5.2.36.2-x86_64.deb
```

未经天融信明确授权，不要将该专有安装包提交到 Git。若使用其他版本，请修改 `Dockerfile` 中的 `ARG TOPSAP_DEB`，并在部署前验证登录流程。

### 配置和启动

在 `secrets/` 中创建以下文件，每个文件只放一个值，并设置权限为 `0600`：

```text
secrets/vpn_server
secrets/vpn_username
secrets/vpn_password
secrets/vpn_totp
```

复制 `.env.example` 为 `.env`，再根据实际 VPN 网络修改其中的网关和目标：

```bash
cp .env.example .env
```

编辑 `.env`：

```dotenv
VPN_GATEWAY_HOST=vpn.example.org
VPN_GATEWAY_PORT=44443
SSH_TARGET=VPN_TARGET_IP
SSH_TARGET_PORT=22
```

启动和查看日志：

```bash
docker compose up -d --build
docker compose logs -f
docker compose ps
```

通过固定 SSH 转发连接目标：

```bash
ssh -p 10022 VPN_USER@127.0.0.1
```

通过 SOCKS5 访问其他 VPN 资源：

```bash
ssh -o 'ProxyCommand=nc -X 5 -x 127.0.0.1:1088 %h %p' user@VPN_RESOURCE
```

WSL2 默认 NAT 网络下，如需让其他可信机器访问固定 SSH 转发，可在管理员 PowerShell 中运行 `windows-expose.ps1`。使用前请检查端口转发和防火墙范围；SOCKS5 端口默认仅监听本机，不应暴露到不可信网络。

### 安全和版权声明

请勿把 VPN 密码、TOTP 密钥写入 Git、镜像、日志或 Issue；TOTP 密钥泄露后应按密码泄露处理并及时更换。TopSAP、Topsec 及相关名称和标识属于天融信（Topsec）或其相应权利人。本项目为独立的社区集成项目，与天融信无赞助、背书或维护关系。TopSAP 软件的全部版权和许可权利仍归原权利人所有。用户应合法获取客户端，并遵守 VPN 服务商的许可、使用条款和安全政策。

### 许可证

本仓库原创代码和配置采用 [MIT License](LICENSE) 发布。该许可证不授予 TopSAP 专有软件、厂商安装包、商标、VPN 凭据或 VPN 服务的使用权利。
