#!/usr/bin/env bash
#  install-clean-m4a2rst.sh  –  run once:  bash install-clean-m4a2rst.sh
#  usage after:  m4a2rst-clean audio.m4a  [model]
set -euo pipefail
BIN=~/bin/m4a2rst-clean
mkdir -p ~/bin
cat > "$BIN" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 0 ]] && { echo "usage: m4a2rst-clean <audio.m4a> [model]"; exit 1; }
a=$1 m=${2:-base} o="${a%.*}.rst"
command -v whisper >/dev/null || { echo "install: pip install -U openai-whisper"; exit 1; }
whisper "$a" --model "$m" --language en --output_format txt -o /tmp >&2
awk 'BEGIN{print "Transcript\n==========\n"} {printf "%s ", $0} END{print "\n"}' /tmp/"$(basename "${a%.*}").txt" > "$o"
echo "Saved → $o"
EOF
chmod +x "$BIN"
grep -q '~/bin' ~/.zshrc || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
echo "Done. Restart shell or run:  source ~/.zshrc"
