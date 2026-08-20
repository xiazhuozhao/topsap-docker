#Requires -RunAsAdministrator

param(
    [string]$Distro = "Ubuntu-22.04",
    [ValidateRange(1, 65535)]
    [int]$ListenPort = 10022,
    [ValidateRange(1, 65535)]
    [int]$WslPort = 10022,
    [string]$RuleName = "TopSAP VPN fixed SSH forward"
)

$ErrorActionPreference = "Stop"

$WslAddresses = (& wsl.exe -d $Distro hostname -I).Trim() -split "\s+"
$WslAddress = $WslAddresses | Where-Object { $_ -match "^\d+\.\d+\.\d+\.\d+$" } | Select-Object -First 1
if (-not $WslAddress) {
    throw "Could not determine the IPv4 address of WSL distribution $Distro"
}

# Refresh the exact forwarding entry because WSL's NAT address can change.
& netsh.exe interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$ListenPort | Out-Null
& netsh.exe interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$ListenPort connectaddress=$WslAddress connectport=$WslPort

$ExistingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
if ($ExistingRule) {
    $ExistingRule | Set-NetFirewallRule -Enabled True -Direction Inbound -Action Allow -Profile Private -RemoteAddress LocalSubnet
} else {
    New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $ListenPort -Profile Private -RemoteAddress LocalSubnet | Out-Null
}

Write-Host "Forwarding Windows TCP/$ListenPort to WSL $WslAddress`:$WslPort for the local subnet."
