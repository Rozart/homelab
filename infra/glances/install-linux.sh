#!/bin/bash
# Install Glances system monitor on Debian/Ubuntu/Raspbian hosts
# Usage: ssh user@host 'bash -s' < install-linux.sh
#
# Targets: proxmox (192.168.0.40), raspbox1 (192.168.0.31),
#          raspbox2 (192.168.0.32), tailscale-lxc (192.168.0.45)

set -euo pipefail

echo "==> Installing Glances..."

sudo apt update
sudo apt install -y python3-pip python3-venv

sudo python3 -m venv /opt/glances
sudo /opt/glances/bin/pip install 'glances[web]'
sudo ln -sf /opt/glances/bin/glances /usr/local/bin/glances

echo "==> Creating systemd service..."

sudo tee /etc/systemd/system/glances.service > /dev/null << 'EOF'
[Unit]
Description=Glances system monitor
After=network.target

[Service]
ExecStart=/usr/local/bin/glances -w --disable-webui
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now glances

echo "==> Glances running on port 61208"
echo "==> Verify: curl http://localhost:61208/api/4/quicklook"
