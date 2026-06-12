#!/bin/sh
# =============================================================================
#  mactune installer
#  https://github.com/Ali-expandings/mactune
#
#    curl -fsSL https://raw.githubusercontent.com/Ali-expandings/mactune/main/install.sh | sh
#
#  Options (pass after `sh -s --`):
#    --desktop   also create a double-clickable "MacTune.command" on your Desktop
#    --prefix D  install into directory D instead of the auto-picked one
#
#  No sudo needed: picks /usr/local/bin when writable, otherwise ~/.local/bin.
#  Installs a single self-contained bash script. Uninstall: rm $(command -v mactune)
# =============================================================================
set -eu

RAW="https://raw.githubusercontent.com/Ali-expandings/mactune/main/mactune"
DESKTOP=0
PREFIX=""

while [ $# -gt 0 ]; do
  case "$1" in
    --desktop) DESKTOP=1 ;;
    --prefix)  shift; PREFIX="${1:-}" ;;
    *) printf 'install.sh: unknown option %s\n' "$1" >&2; exit 64 ;;
  esac
  shift
done

case "$(uname -s 2>/dev/null)" in
  Darwin) : ;;
  *) printf 'mactune is a macOS tool — this system is not macOS.\n' >&2; exit 1 ;;
esac

# Pick an install dir: explicit --prefix > writable /usr/local/bin > ~/.local/bin
if [ -z "$PREFIX" ]; then
  if [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
    PREFIX=/usr/local/bin
  else
    PREFIX="$HOME/.local/bin"
  fi
fi
mkdir -p "$PREFIX"

TMP=$(mktemp /tmp/mactune.XXXXXX)
trap 'rm -f "$TMP"' EXIT

printf '» downloading mactune…\n'
curl -fsSL "$RAW" -o "$TMP"

# Sanity: did we actually get the script, not an error page?
head -1 "$TMP" | grep -q '^#!/bin/bash' || {
  printf 'install.sh: download did not look like mactune — aborting.\n' >&2
  exit 1
}

install -m 0755 "$TMP" "$PREFIX/mactune"
printf '✓ installed: %s/mactune\n' "$PREFIX"

# Double-click launcher (optional): a tiny wrapper so Finder users never
# need a terminal. Created locally, so Gatekeeper quarantine never applies.
if [ "$DESKTOP" = "1" ] && [ -d "$HOME/Desktop" ]; then
  {
    printf '#!/bin/bash\n'
    printf 'exec "%s/mactune" "$@"\n' "$PREFIX"
  } > "$HOME/Desktop/MacTune.command"
  chmod +x "$HOME/Desktop/MacTune.command"
  printf '✓ Desktop launcher: ~/Desktop/MacTune.command (double-click to run)\n'
fi

# PATH hint if the chosen dir isn't reachable
case ":$PATH:" in
  *":$PREFIX:"*)
    printf '✓ ready — run: mactune\n' ;;
  *)
    printf '▲ %s is not on your PATH. Add this line to ~/.zprofile:\n' "$PREFIX"
    printf '    export PATH="%s:$PATH"\n' "$PREFIX"
    printf '  then open a new terminal and run: mactune\n' ;;
esac
