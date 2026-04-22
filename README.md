# ansible-role-sync_haproxy_certs

Installs the `sync-haproxy-certs` script and its systemd units into the AMI. Intended for use in packer builds alongside `ansible-role-haproxy`.

Runtime configuration is handled by `ansible-role-update_sync_haproxy_certs_config`.

## Files installed

- `/usr/local/bin/sync-haproxy-certs.sh` — syncs certificates from S3; exits 2 when files changed, 0 when unchanged, 1 on error
- `/etc/systemd/system/sync-certificates.service` — oneshot service
- `/etc/systemd/system/sync-certificates.timer` — runs service every 3h

## Variables

None. This role installs static files only.
