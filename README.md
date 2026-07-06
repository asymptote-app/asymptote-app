# asymptote — install

Prebuilt binaries and the installer for **asymptote**, the local AI work-cost
ledger for coding agents. This repo hosts public releases; the source is
managed separately.

## Install

```sh
curl -fsSL asymptote.app/install | sh
```

The [installer](install.sh) detects your OS/arch (linux/darwin × amd64/arm64),
downloads the matching binary from this repo's latest
[Release](https://github.com/asymptote-app/cli/releases/latest), verifies it
against `checksums.txt`, and installs it to `/usr/local/bin` (or `~/.local/bin`).

Homepage: https://asymptote.app
