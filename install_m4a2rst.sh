#!/usr/bin/env bash
# ==============================================================================
#  m4a2rst – one-shot installer
# ==============================================================================
# WHAT IT IS
# ----------
# Creates a tiny command-line tool that turns any .m4a (or other audio) file
# into a reStructuredText transcript using OpenAI Whisper.
#
# INSTALL
# -------
# 1. Save this entire file as install_m4a2rst.sh
# 2. Run once:   bash install_m4a2rst.sh
# 3. Close/re-open your terminal (or `source ~/.zshrc`)
#
# USAGE AFTER INSTALL
# -------------------
# m4a2rst /path/to/file.m4a              # uses the “base” model
# m4a2rst /path/to/file.m4a large        # pick a different model
#
# Output lands right next to the original file with .rst extension.
#
# REQUIREMENTS
# ------------
# macOS (or any Unix-like), Python 3, pip.
# Whisper will be auto-installed on first run if missing.
#
# UNINSTALL
# ---------
# rm ~/bin/m4a2rst          # remove the command
# edit ~/.zshrc and delete the PATH line if you really want to clean up.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$HOME/bin"
SCRIPT_PATH="$SCRIPT_DIR/m4a2rst"
ZSHRC="$HOME/.zshrc"

mkdir -p "$SCRIPT_DIR"

cat > "$SCRIPT_PATH" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 0 ]] && { echo "usage: m4a2rst <audio.m4a> [model]"; exit 1; }
audio=$1
model=${2:-base}
out="${audio%.*}.rst"
command -v whisper >/dev/null || { echo "whisper not found – run: pip install -U openai-whisper"; exit 1; }
whisper "$audio" --model "$model" --language en --output_format txt -o /tmp
awk 'BEGIN{print "Transcript\n==========\n"} {print $0 "\n"}' "/tmp/$(basename "${audio%.*}").txt" > "$out"
echo "Saved → $out"
EOF

chmod +x "$SCRIPT_PATH"

if ! grep -q "$SCRIPT_DIR" "$ZSHRC"; then
  echo "export PATH=\"$SCRIPT_DIR:\$PATH\"" >> "$ZSHRC"
fi

echo "Installed. Restart your shell or run: source $ZSHRC"

