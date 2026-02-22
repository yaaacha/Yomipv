#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Menjalankan Setup Yomipv...${NC}"

# 1. Cek Node.js
if ! command -v node &> /dev/null; then
    echo "Error: Node.js belum terinstall. Silakan install dulu di https://nodejs.org/"
    exit 1
fi

# 2. Install dependencies lookup-app
echo -e "${GREEN}Menginstall dependencies Node.js...${NC}"
cd scripts/yomipv/lookup-app && npm install
cd ../../../

# 3. Tambah Alias ke .zshrc atau .bashrc
SHELL_CONFIG="$HOME/.zshrc"
[ ! -f "$SHELL_CONFIG" ] && SHELL_CONFIG="$HOME/.bashrc"

ALIAS_CMD="alias yomipv='(cd ~/.config/mpv/scripts/yomipv/lookup-app && npm start &) && mpv'"

if ! grep -q "alias yomipv" "$SHELL_CONFIG"; then
    echo -e "${GREEN}Menambahkan alias 'yomipv' ke $SHELL_CONFIG...${NC}"
    echo "" >> "$SHELL_CONFIG"
    echo "# Yomipv Shortcut" >> "$SHELL_CONFIG"
    echo "$ALIAS_CMD" >> "$SHELL_CONFIG"
    echo -e "${BLUE}Restart terminal atau ketik 'source $SHELL_CONFIG' untuk mengaktifkan alias.${NC}"
else
    echo "Alias 'yomipv' sudah ada."
fi

echo -e "${GREEN}Setup selesai! Sekarang lo bisa jalanin 'yomipv' di terminal.${NC}"