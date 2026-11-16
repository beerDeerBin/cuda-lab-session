#!/usr/bin/env bash
# =====================================================================
# CUDA Lab – setup
# Installs the recommended VS Code extensions and opens the lab in VS Code.
#
#   bash setup.sh
#
# The extension list comes from .vscode/extensions.json, so there is only
# one place to change it.
# =====================================================================

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_FILE="$LAB_DIR/.vscode/extensions.json"

green() { printf '\033[32m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }

echo "CUDA Lab setup"
echo "=============================================="

# --- 1) Find the VS Code command-line tool -------------------------------
CODE=""
for c in code code-insiders codium; do
    if command -v "$c" >/dev/null 2>&1; then CODE="$c"; break; fi
done
if [ -z "$CODE" ]; then
    red "VS Code command 'code' not found."
    info "Install VS Code, or add its 'bin' folder to your PATH, then run this script again."
    exit 1
fi
green "VS Code found: $(command -v "$CODE")"

# --- 2) Read the recommended extensions -----------------------------------
if [ ! -f "$EXT_FILE" ]; then
    red "Missing $EXT_FILE"
    exit 1
fi
# every "publisher.name" string inside the recommendations list
EXTENSIONS=$(tr -d '\n' < "$EXT_FILE" \
    | sed -E 's/.*"recommendations"[[:space:]]*:[[:space:]]*\[([^]]*)\].*/\1/' \
    | grep -oE '"[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+"' | tr -d '"')
if [ -z "$EXTENSIONS" ]; then
    red "No extensions found in $EXT_FILE"
    exit 1
fi

# --- 3) Install the ones that are missing ---------------------------------
echo
echo "Extensions:"
INSTALLED=$("$CODE" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
FAILED=0
for ext in $EXTENSIONS; do
    lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if echo "$INSTALLED" | grep -qx "$lower"; then
        info "already installed  $ext"
    elif "$CODE" --install-extension "$ext" --force >/dev/null 2>&1; then
        green "  installed          $ext"
    else
        red   "  FAILED             $ext"
        FAILED=1
    fi
done

# --- 4) Quick check of the CUDA tools (only warnings) ---------------------
echo
echo "CUDA tools:"
[ -d /usr/local/cuda/bin ] && case ":$PATH:" in *":/usr/local/cuda/bin:"*) ;; *) export PATH="/usr/local/cuda/bin:$PATH" ;; esac
for tool in nvidia-smi nvcc; do
    if command -v "$tool" >/dev/null 2>&1; then info "ok                 $tool"
    else red "  not found          $tool  (ask your teacher)"; fi
done
if ! command -v nvcc >/dev/null 2>&1 && [ -x /usr/local/cuda/bin/nvcc ]; then
    info "Tip: add CUDA to your PATH:  echo 'export PATH=/usr/local/cuda/bin:\$PATH' >> ~/.bashrc"
fi

# --- 5) Open the lab in VS Code -------------------------------------------
echo
green "Opening the lab in VS Code ..."
"$CODE" "$LAB_DIR"
# open the README and the first exercise in that window
"$CODE" -r "$LAB_DIR/starter/README.md" "$LAB_DIR/starter/ex0_warmup.cu"

echo
if [ "$FAILED" -ne 0 ]; then
    red "Some extensions could not be installed. Install them in VS Code:"
    info "Ctrl+Shift+X -> type @recommended -> install all"
else
    green "Done. Use the buttons at the bottom of VS Code: Build · Run · Test"
fi
