# Docker startup after Tailscale

Database containers publish ports on the host's Tailscale IP. Starting Docker
before that IP exists can leave containers without working networking.

This system-service drop-in uses Tailscale's packaged `tailscale-online.target`,
which runs `tailscale wait` until the interface and IP are ready. All Docker
containers consequently wait for Tailscale at daemon startup.

Install from the dotfiles root (source-only; do not Stow):

```sh
sudo install -Dm644 extras/docker/tailscale-online.conf \
  /etc/systemd/system/docker.service.d/tailscale-online.conf
sudo systemctl daemon-reload
```

No Docker restart is required to load the ordering for its next startup.
To recover the existing database containers once `tailscale wait` succeeds:

```sh
docker restart local-databases-postgres-1 local-databases-mysql-1
```

If `docker inspect` shows empty `NetworkSettings.Networks` after the failed
startup, restarting alone does not restore the missing network attachments.
Reconnect only the affected, detached containers to the existing network:

```sh
docker network connect local-databases_default local-databases-postgres-1
docker network connect local-databases_default local-databases-mysql-1
```

Verify the ordering with `systemctl show docker.service -p Requires -p After`.
After the next boot, verify both published database ports accept connections.

To remove this ordering, delete only
`/etc/systemd/system/docker.service.d/tailscale-online.conf` and run
`sudo systemctl daemon-reload`.
