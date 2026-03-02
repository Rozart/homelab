# Dispatcharr

IPTV stream management and proxy with VPN routing.

## Services

| Service | Purpose | Port |
|---------|---------|------|
| `dispatcharr` | IPTV proxy, EPG management, HDHomeRun emulation | 9191 (via VPN) |
| `dispatcharr-vpn` | Gluetun VPN tunnel (Mullvad/WireGuard) | - |

## Deploy

Deployed on **media-host** (192.168.0.49).

```bash
cp .env.example .env
# Fill in Mullvad VPN keys
docker compose up -d
```

Accessible via `dispatcharr.home.rozart.dev`.

## Setup

### 1. Add IPTV source

Open the Dispatcharr web UI and add your IPTV provider:

- **M3U**: paste the M3U playlist URL
- **Xtream Codes**: enter server URL, username, and password

Dispatcharr imports all channels and EPG data.

### 2. Map channels and EPG

Use the Dispatcharr UI to:

- Map channels to EPG sources
- Remove unwanted channels
- Organize channel groups

### 3. Connect Jellyfin

1. In **Jellyfin** → Dashboard → Live TV → **Add Tuner Device**
   - Type: **HDHomeRun**
   - Tuner URL: `http://192.168.0.49:9191`
2. Add guide data:
   - EPG URL from Dispatcharr (shown in its settings)
3. Jellyfin now has live TV with a full program guide

## Architecture

All IPTV traffic is routed through the VPN tunnel:

```
IPTV provider → VPN (gluetun) → Dispatcharr → Jellyfin → clients
```

## VPN

Uses its own Gluetun instance (separate from the downloader stack). Can reuse the same Mullvad WireGuard keys or generate new ones.
