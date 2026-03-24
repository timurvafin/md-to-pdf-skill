#!/usr/bin/env bash
set -euo pipefail

# MD to PDF converter using pandoc + Chrome headless
# Usage: convert.sh -i input.md [-o output.pdf] [-t theme] [-l]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$SKILL_DIR/assets"

# Defaults
INPUT=""
OUTPUT=""
THEME="professional"
LANDSCAPE=false
TMPDIR_PREFIX="/tmp/md2pdf-$$"
CLEANUP_FILES=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
  cat <<EOF
Usage: $(basename "$0") -i INPUT.md [-o OUTPUT.pdf] [-t THEME] [-l]

Options:
  -i FILE     Input Markdown file (required)
  -o FILE     Output PDF file (default: input name with .pdf extension)
  -t THEME    Theme name: professional, modern, academic, dark, minimal
              (default: professional)
  -l          Landscape orientation (default: portrait)
  -h          Show this help

Themes are CSS files in: $ASSETS_DIR/
EOF
  exit 0
}

cleanup() {
  for f in "${CLEANUP_FILES[@]+"${CLEANUP_FILES[@]}"}"; do
    [ -f "$f" ] && rm -f "$f"
  done
}
trap cleanup EXIT

log() {
  echo -e "${GREEN}[md2pdf]${NC} $*" >&2
}

warn() {
  echo -e "${YELLOW}[md2pdf]${NC} $*" >&2
}

error() {
  echo -e "${RED}[md2pdf]${NC} $*" >&2
  exit 1
}

# --- Detect tools ---

has_pandoc() {
  command -v pandoc &>/dev/null
}

has_chrome() {
  # macOS Chrome locations
  if [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    return 0
  elif command -v google-chrome &>/dev/null; then
    return 0
  elif command -v chromium &>/dev/null; then
    return 0
  fi
  return 1
}

get_chrome_cmd() {
  if [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    echo "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  elif command -v google-chrome &>/dev/null; then
    echo "google-chrome"
  elif command -v chromium &>/dev/null; then
    echo "chromium"
  fi
}

check_dependencies() {
  has_pandoc || error "pandoc not found. Install: brew install pandoc"
  has_chrome || error "Chrome not found. Install Google Chrome or Chromium"
}

# --- Conversion functions ---

convert_pandoc_chrome() {
  local input="$1" output="$2" css="$3"
  local tmphtml="${TMPDIR_PREFIX}.html"
  CLEANUP_FILES+=("$tmphtml")

  log "Backend: pandoc + Chrome headless"
  log "Converting MD → HTML..."

  # Get the directory of the input file for resource resolution
  local input_dir
  input_dir="$(cd "$(dirname "$input")" && pwd)"

  # Build pandoc CSS args
  local css_args=(--css="$css")
  if [ "$LANDSCAPE" = true ]; then
    local override_css="${TMPDIR_PREFIX}-override.css"
    CLEANUP_FILES+=("$override_css")
    echo "@page { size: A4 landscape; }" > "$override_css"
    css_args+=(--css="$override_css")
  fi

  pandoc -f gfm+hard_line_breaks+smart+definition_lists+implicit_figures "$input" \
    -o "$tmphtml" \
    --standalone \
    --embed-resources \
    --resource-path="$input_dir" \
    "${css_args[@]}" \
    --highlight-style=kate \
    --metadata title=" " \
    2>&1 || error "pandoc conversion failed"

  log "Converting HTML → PDF via Chrome..."

  local chrome_cmd
  chrome_cmd="$(get_chrome_cmd)"

  "$chrome_cmd" \
    --headless=new \
    --disable-gpu \
    --no-pdf-header-footer \
    --disable-background-networking \
    --disable-default-apps \
    --disable-extensions \
    --disable-sync \
    --run-all-compositor-stages-before-draw \
    --print-to-pdf="$output" \
    "$tmphtml" \
    2>/dev/null || error "Chrome PDF generation failed"

  log "Done: $output"
}

# --- Parse arguments ---

while getopts "i:o:t:lh" opt; do
  case $opt in
    i) INPUT="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    t) THEME="$OPTARG" ;;
    l) LANDSCAPE=true ;;
    h) usage ;;
    *) usage ;;
  esac
done

# Validate input
[ -z "$INPUT" ] && error "Input file is required. Use -i FILE"
[ -f "$INPUT" ] || error "Input file not found: $INPUT"

# Resolve input to absolute path
INPUT="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"

# Default output: same name, .pdf extension
if [ -z "$OUTPUT" ]; then
  OUTPUT="${INPUT%.md}.pdf"
fi

# Resolve output to absolute path (handle relative paths)
if [[ "$OUTPUT" != /* ]]; then
  OUTPUT="$(pwd)/$OUTPUT"
fi

# Resolve theme CSS
CSS_FILE="$ASSETS_DIR/theme-${THEME}.css"
[ -f "$CSS_FILE" ] || error "Theme not found: $CSS_FILE
Available themes: professional, modern, academic, dark, minimal"

# Check dependencies and run conversion
check_dependencies
convert_pandoc_chrome "$INPUT" "$OUTPUT" "$CSS_FILE"
