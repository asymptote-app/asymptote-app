#!/bin/sh
# Asymptote installer — https://github.com/asymptote-app/asymptote
#
#   curl -fsSL asymptote.app/install | sh
#   (or) curl -fsSL https://raw.githubusercontent.com/asymptote-app/asymptote/main/scripts/install.sh | sh
#
# Detects OS/arch, downloads the latest release binary from GitHub Releases,
# verifies it against checksums.txt, and installs it to the first writable of
# /usr/local/bin or ~/.local/bin. POSIX sh, no dependencies beyond curl.
set -eu

REPO="asymptote-app/installer"
BASE="https://github.com/$REPO/releases/latest/download"

# --- detect platform ---------------------------------------------------------
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
  linux|darwin) ;;
  *) echo "asymptote: unsupported OS: $OS (linux and darwin only)" >&2; exit 1 ;;
esac

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64)  ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) echo "asymptote: unsupported arch: $ARCH (amd64 and arm64 only)" >&2; exit 1 ;;
esac

BIN="asymptote-$OS-$ARCH"

# --- download + verify -------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "downloading $BIN (latest release)..."
curl -fsSL -o "$TMP/$BIN" "$BASE/$BIN"
curl -fsSL -o "$TMP/checksums.txt" "$BASE/checksums.txt"

EXPECTED=$(grep " $BIN\$" "$TMP/checksums.txt" | awk '{print $1}')
if [ -z "$EXPECTED" ]; then
  echo "asymptote: $BIN not found in checksums.txt — aborting" >&2; exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL=$(sha256sum "$TMP/$BIN" | awk '{print $1}')
else
  ACTUAL=$(shasum -a 256 "$TMP/$BIN" | awk '{print $1}')
fi
if [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "asymptote: checksum mismatch — aborting" >&2
  echo "  expected: $EXPECTED" >&2
  echo "  got:      $ACTUAL" >&2
  exit 1
fi

# --- install -----------------------------------------------------------------
chmod +x "$TMP/$BIN"
for DIR in /usr/local/bin "$HOME/.local/bin"; do
  if [ -d "$DIR" ] && [ -w "$DIR" ]; then
    INSTALL_DIR="$DIR"; break
  fi
done
if [ -z "${INSTALL_DIR:-}" ]; then
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
fi

mv "$TMP/$BIN" "$INSTALL_DIR/asymptote"
echo "installed: $INSTALL_DIR/asymptote ($("$INSTALL_DIR/asymptote" --version 2>/dev/null || echo unknown))"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo "note: $INSTALL_DIR is not on your PATH — add it to your shell profile." ;;
esac

cat <<'EOF'

quickstart:
  asymptote import          # instant history from your existing agent logs
  asymptote run -- claude   # capture a session on the wire
  asymptote stats           # where the tokens went, priced at API rates
  asymptote enable          # always-on capture (daemon + settings injection)
EOF
