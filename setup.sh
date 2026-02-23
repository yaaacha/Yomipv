#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}== Yomipv Setup Tool for MacOS/Linux ==${NC}"

# 1. Cek Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Error: Node.js belum terinstall. Silakan install di https://nodejs.org/${NC}"
    exit 1
fi

# 2. Install dependencies lookup-app
echo -e "${GREEN}Installing Node.js dependencies...${NC}"
cd scripts/yomipv/lookup-app && npm install
cd ../../../

# 3. Beri izin eksekusi (Penting buat Mac)
echo -e "${GREEN}Setting permissions...${NC}"
chmod +x scripts/yomipv/lookup-app/node_modules/.bin/electron 2>/dev/null

# 4. Tambah Alias ke .zshrc atau .bashrc
SHELL_CONFIG="$HOME/.zshrc"
[ ! -f "$SHELL_CONFIG" ] && SHELL_CONFIG="$HOME/.bashrc"

# Alias yang otomatis masuk ke folder config MPV
ALIAS_CMD="alias yomipv='(cd ~/.config/mpv/scripts/yomipv/lookup-app && npm start &) && mpv'"

if ! grep -q "alias yomipv" "$SHELL_CONFIG"; then
    echo -e "${GREEN}Adding 'yomipv' alias to $SHELL_CONFIG...${NC}"
    echo "" >> "$SHELL_CONFIG"
    echo "# Yomipv Shortcut" >> "$SHELL_CONFIG"
    echo "$ALIAS_CMD" >> "$SHELL_CONFIG"
    echo -e "${BLUE}Restart terminal atau ketik 'source $SHELL_CONFIG' untuk mengaktifkan.${NC}"
else
    echo -e "${YELLOW}Alias 'yomipv' sudah ada.${NC}"
fi

echo -e "${GREEN}Setup Selesai! Cukup ketik 'yomipv' untuk mulai mining.${NC}"