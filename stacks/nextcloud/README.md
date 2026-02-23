# Nextcloud

Central file management hub with Google Drive bidirectional sync.

## Prerequisites

### NAS (Synology)

1. Create shared folder `/volume1/cloud` with data checksums enabled
2. Create subdirectories:

   ```
   companies/<company-a>/
   companies/<company-b>/
   ...
   private/shared/
   private/<user-a>/
   private/<user-b>/
   ...
   obsidian/
   ```

3. Add NFS permission rule for the Docker host IP:
   - Privilege: Read/Write
   - Squash: Map all users to admin (`all_squash`)
   - Security: sys
   - Enable async: Yes

### Docker host

1. Add to `/etc/fstab`:

   ```
   192.168.0.36:/volume1/cloud  /mnt/nas/cloud  nfs  defaults,nofail,bg,soft,local_lock=all  0  0
   ```

2. Mount:

   ```bash
   sudo mkdir -p /mnt/nas/cloud
   sudo mount /mnt/nas/cloud
   ```

## Deploy

```bash
cp .env.example .env
# edit .env — set a real database password
docker compose up -d
```

## Post-deploy setup

Wait for Nextcloud to finish initial setup (first start takes a minute), then run:

```bash
# Install and enable apps
docker exec -u www-data nextcloud php occ app:install files_external
docker exec -u www-data nextcloud php occ app:enable files_external
docker exec -u www-data nextcloud php occ config:app:set files_external allow_create_new_local --value=yes

# Set default phone region and background jobs
docker exec -u www-data nextcloud php occ config:system:set default_phone_region --value=PL
docker exec -u www-data nextcloud php occ background:cron

# Create users (will prompt for passwords)
docker exec -it -u www-data nextcloud php occ user:add --display-name="<Name>" <username>
```

### External Storage mounts

Configure in **Profile avatar (top right) → Administration settings → External storage**. Add each as type **Local**:

| Folder name   | Path                            | Users          |
| ------------- | ------------------------------- | -------------- |
| _per company_ | `/mnt/companies/<company-name>` | admin          |
| private       | `/mnt/private`                  | all            |
| obsidian      | `/mnt/obsidian`                 | admin          |
| scan-inbox    | `/mnt/scan-inbox`               | admin          |
| books-ingest  | `/mnt/books-ingest`             | admin          |
| photos-import | `/mnt/photos-import`            | admin + family |

### Google Drive sync (rclone)

1. On a machine with a browser, install rclone and configure remotes via `rclone config` (type: Google Drive).
   For Shared Drives, answer `y` when asked "Configure this as a Shared Drive?" and select the drive.
   **Important:** For Shared Drive remotes, ensure `root_folder_id` is empty — only `team_drive` should be set.

2. Copy the config to the Docker host:

   ```bash
   scp ~/.config/rclone/rclone.conf <docker-host>:/home/rozart/docker/stacks/nextcloud/appdata/rclone/rclone.conf
   ```

3. Create `appdata/rclone/bisync.conf` with sync mappings (one per line):

   ```
   # format: <remote>:<remote-path>|<local-folder>
   # <local-folder> maps to a subdirectory under companies/ on the NAS
   my-remote:Some Drive Folder|folder-a
   my-remote:Another Folder|folder-b
   my-shared-drive-remote:|folder-c
   ```

4. Verify each remote lists the expected content before syncing:

   ```bash
   docker exec nextcloud_rclone rclone lsd "<remote>:<remote-path>" --max-depth 1
   ```

5. Initial sync — always pull one-direction first, then establish bisync baseline:

   ```bash
   # One-direction pull (remote → local, won't upload anything)
   docker exec nextcloud_rclone rclone sync "<remote>:<remote-path>" /data/<local-folder> -v

   # Verify local content is correct
   docker exec nextcloud_rclone ls /data/<local-folder>/

   # Establish bisync baseline (both sides already match, nothing transfers)
   docker exec nextcloud_rclone rclone bisync "<remote>:<remote-path>" /data/<local-folder> --resync
   ```

   **Never run `--resync` with leftover local files** — bisync will push them to the remote.

   After this, the sidecar loop handles sync automatically every `RCLONE_BISYNC_INTERVAL`.

## macOS access via WebDAV

Mount Nextcloud as a network drive in Finder for drag-and-drop without syncing everything locally:

1. Finder → Go → Connect to Server (Cmd+K)
2. Enter: `https://cloud.home.rozart.dev/remote.php/dav/files/<your-username>/`
3. Enter Nextcloud credentials

## Verification

- [ ] `https://cloud.home.rozart.dev` — login works
- [ ] Company folders visible, match Google Drive contents
- [ ] File added in Google Drive appears in Nextcloud within sync interval (and vice versa)
- [ ] Upload PDF to Scan Inbox → Paperless processes it
- [ ] Drop EPUB in Books Ingest → CWA ingests it
- [ ] Drop photo in Photos Import → Immich picks it up
- [ ] Non-admin user logs in — sees only their private folder + shared, not company docs
- [ ] Stack restart → all data persists
