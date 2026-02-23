# Media VM (roz-media-host)

Dedicated Proxmox VM for media services (*Arr stack, Jellyfin, download clients).

## Proxmox VM Settings

- **VM ID**: pick next available
- **Name**: `roz-media-host`
- **OS**: Ubuntu Server 24.04
- **Machine**: q35, UEFI (OVMF)
- **CPU**: 8 cores, type: host
- **RAM**: 16 GB (ballooning off)
- **Disk 1**: 50 GB (local-zfs) — OS + Docker + appdata
- **Disk 2**: 150 GB (data) — active downloads
- **Network**: vmbr0, VirtIO
- **SCSI Controller**: VirtIO SCSI single
- **Qemu Agent**: enabled
- **Discard**: checked on both disks

## Static IP

- **IP**: 192.168.0.49/24
- **Gateway**: 192.168.0.1
- **DNS**: 192.168.0.31 (Pi-hole)

## Post-install setup

### 1. Dotfiles

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <github-user>/<chezmoi-repo>
chsh -s $(which fish)
```

### 2. Downloads disk

```bash
sudo mkfs.ext4 /dev/sdb
sudo mkdir -p /mnt/downloads
sudo mount /dev/sdb /mnt/downloads
sudo chown rozart:rozart /mnt/downloads
echo "/dev/sdb /mnt/downloads ext4 defaults,nofail,discard 0 2" | sudo tee -a /etc/fstab
```

### 3. NAS mount

Create Synology shared folder `/volume1/media` with:
- Data checksums enabled
- NFS permission for 192.168.0.49: Read/Write, `all_squash`, async, security `sys`

```bash
sudo apt install -y nfs-common
sudo mkdir -p /mnt/nas/media
echo "192.168.0.36:/volume1/media /mnt/nas/media nfs nfsvers=4,defaults,nofail,bg,soft,local_lock=all 0 0" | sudo tee -a /etc/fstab
sudo mount /mnt/nas/media
```

### 4. NAS folder structure

```
/mnt/nas/media/
├── torrents/
│   ├── movies/
│   ├── tv/
│   ├── audiobooks/
│   └── ebooks/
├── usenet/
│   ├── movies/
│   ├── tv/
│   ├── audiobooks/
│   └── ebooks/
├── movies/         ← Radarr library
├── tv/             ← Sonarr library
├── audiobooks/     ← Audiobookshelf library
└── ebooks/         ← Readarr → CWA ingest on docker-host
```

### 5. Docker network

```bash
docker network create home-network
```

### 6. Komodo periphery

Install the Komodo periphery agent for centralized management. See `infra/komodo-periphery/` for reference configs.

### 7. GPU passthrough (optional, future)

AMD iGPU available on Proxmox host. Requires enabling IOMMU:
1. Add `amd_iommu=on` to kernel cmdline in `/etc/default/grub`
2. `update-grub && reboot` on Proxmox host
3. Pass through `/dev/dri/renderD128` to the VM
4. Configure Jellyfin for VAAPI transcoding
