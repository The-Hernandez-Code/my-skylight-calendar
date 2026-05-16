# My-Skylight-Calendar

Project workspace on Windows for an app deployed to a Raspberry Pi acting as a
wall-mounted family kitchen calendar / task board (Skylight Calendar replacement).

The previous implementation (`rasberry-pi-home-calendar`, FastAPI/uvicorn on port
8000) was removed from the Pi on 2026-05-11. The Pi is currently a clean baseline
awaiting a fresh deployment.

The upstream reference repo is <https://github.com/mohesles/my-skylight-calendar>
(added as `origin`). It is a **Home Assistant YAML configuration** (packages,
themes, dashboard, HACS-based frontend cards) — **not** a Python/Node web app.
Deployment requires Home Assistant running on (or reachable from) the Pi.

---

## Deployment target: Raspberry Pi "PaPi"

| Field    | Value |
| ---      | --- |
| Hostname | `PaPi` (mDNS: `papi.local`) |
| LAN IP   | `10.0.0.202` |
| User     | `papi` |
| OS       | Debian 13 "Trixie" (Raspberry Pi OS, 64-bit) |
| Arch     | aarch64 (likely Pi 4 / Pi 5, 4 GB RAM) |
| Storage  | `/dev/sda2` — booting from USB SSD, 58 GB total, ~50 GB free |
| Auth     | passwordless ed25519 key from this Windows machine |
| Sudo     | `papi` has **passwordless sudo** (`sudo -n` works) |

### Connecting from this Windows machine

```powershell
ssh papi              # uses the alias in ~/.ssh/config
ssh papi@10.0.0.202   # equivalent, more explicit
```

The `papi` alias is configured at `C:\Users\TonyHernandez\.ssh\config`.
The private key is at `C:\Users\TonyHernandez\.ssh\id_ed25519` (Windows side).
The Pi's public key for GitHub auth is at `~/.ssh/id_ed25519.pub` on the Pi
itself, already added to GitHub user `The-Hernandez-Code`.

### Running commands on the Pi from Claude Code (non-interactive)

The standard pattern — works without prompts:

```powershell
ssh papi "<single command>"
```

For multi-line scripts, pipe via stdin so PowerShell's quote-escaping doesn't
mangle anything:

```powershell
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
[Console]::OutputEncoding = $OutputEncoding
ssh papi @"
echo step 1
echo step 2
"@
```

**The `$OutputEncoding` lines are required** when piping multi-line scripts —
PowerShell's default encoding will inject a UTF-8 BOM on the first line and bash
will fail with `bash: ﻿echo: command not found` or
`syntax error near unexpected token 'then'`. Setting UTF-8 without BOM fixes it.

**The same BOM trap applies when writing config files from PowerShell.** Do
**not** use `Set-Content -Encoding utf8` or `Out-File -Encoding utf8` for files
that strict parsers will read (SSH config, shell scripts, bash heredocs, etc.) —
PowerShell 5.1's `utf8` adds a BOM. Use this instead:

```powershell
[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
```

Avoid these over `ssh papi "..."`:

- Interactive programs (vim, nano, htop, raspi-config, `apt` confirmation prompts) — they need a TTY
- `sudo` without `-n` if you need to detect the password prompt (papi has passwordless sudo, so just `sudo` works)
- `apt install` without `-y` — will hang on the "Y/n" prompt

---

## What's installed on the Pi (clean baseline)

| Category  | Tools |
| ---       | --- |
| Languages | Python 3.13.5, Node 20.20.0, npm 10.8.2, pip 25.1.1, gcc 14.2.0 |
| Tooling   | git 2.47.3, make 4.4.1, curl 8.14.1, wget, htop, nano |
| Desktop   | LightDM + LXDE (GUI starts on boot, useful for kiosk mode) |
| Services  | ssh, avahi-daemon (mDNS), cups, bluetooth, NetworkManager |

**Not installed:** Docker, Go, Rust, Java, vim, tmux. Add via `apt install -y` as needed.

---

## GitHub access from the Pi

The Pi uses an SSH key (not a PAT) for GitHub. Clone with SSH URLs:

```bash
git clone git@github.com:The-Hernandez-Code/<repo>.git
```

Verify auth with:

```bash
ssh -T git@github.com   # expect: "Hi The-Hernandez-Code! ..."  (exit code 1 is normal)
```

**Never embed PATs in remote URLs.** A previous PAT leaked via `git remote -v`
output and had to be revoked. If a PAT is genuinely needed (e.g. API scripts),
store it via `gh auth login` or `git config --global credential.helper store`.

---

## Previous deployment shape (for reference only — superseded by HA approach)

The removed FastAPI app used this pattern:

- **App location:** `/home/papi/<project-name>/`
- **Python venv:** `<project>/venv/`
- **Web server:** `uvicorn app.main:app --host 0.0.0.0 --port 8000`
- **systemd unit:** `/etc/systemd/system/kitchen-calendar.service` (Type=simple, User=papi, Restart=on-failure)
- **Kiosk autostart:** `~/.config/autostart/<name>-kiosk.desktop` running `chromium --kiosk http://localhost:8000`
- **SQLite DB:** `<project>/data/calendar.db`

Port 8000 is currently free.

The new HA-based approach will not use uvicorn; HA's frontend lives on port 8123
by default. The kiosk autostart pattern still applies — just point Chromium at
the HA URL instead.

---

## Workflow notes for Claude Code sessions

- **Repo state:** this directory is a git repo (`git init` on 2026-05-11) with
  remote `origin` pointing to <https://github.com/mohesles/my-skylight-calendar>.
  No working-tree files yet besides `CLAUDE.md` and `.claude/`.
- **Most "do something on the Pi" tasks** can be done via `ssh papi "..."` from this session — no separate terminal needed.
- **Use the explicit IP** (`10.0.0.202`) in scripted commands when robustness matters — mDNS sometimes fails to resolve on Windows. The `ssh papi` alias resolves to the IP anyway.

---

## Known network caveat

The Pi briefly went unreachable (`Connection timed out`) once during the
2026-05-11 session, then recovered. Likely transient Wi-Fi. If SSH suddenly
times out, retry — don't assume the Pi died.
