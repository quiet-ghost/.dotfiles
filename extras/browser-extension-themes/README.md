# Chromium and Helium extension themes

Omarchy's mandatory `BrowserThemeColor` policy overrides Chrome Web Store themes
in both browsers. The user-level `omarchy-theme-set-browser` override avoids
normal writes, but package scripts and commands with a different PATH can bypass
it. A post-update `sudo -n rm` is not reliable once sudo authorization expires.

This root-owned systemd path unit removes only
`/etc/chromium/policies/managed/color.json` whenever it exists, including at boot
and after updates. Other policies (including `omarchy.json`), profiles, and
extensions are untouched. No passwordless sudo rule is needed.

Install from the dotfiles root (source-only; do not Stow):

```sh
sudo bash extras/browser-extension-themes/install.sh
```

The first removed policy is backed up to
`/var/lib/browser-extension-themes/color.json.bak`. Installed units live under
`/etc/systemd/system`, outside package-owned Omarchy files.

Verify:

```sh
systemctl is-enabled browser-extension-themes.path
systemctl is-active browser-extension-themes.path
test ! -e /etc/chromium/policies/managed/color.json
journalctl -u browser-extension-themes.service -n 10 --no-pager
```

To test recreation deliberately, run `/usr/bin/omarchy-theme-set-browser` and
check that `color.json` disappears again. Refresh running browsers afterward:

```sh
helium-browser --refresh-platform-policy --no-startup-window
chromium --refresh-platform-policy --no-startup-window
```

To remove the guard:

```sh
sudo systemctl disable --now browser-extension-themes.path
sudo rm -- /etc/systemd/system/browser-extension-themes.path \
  /etc/systemd/system/browser-extension-themes.service
sudo systemctl daemon-reload
```
