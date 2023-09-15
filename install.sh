#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Symbols
CHECKMARK='\xE2\x9C\x94'
ROCKET='\xF0\x9F\x9A\x80'
CROSSMARK='\xE2\x9C\x98'
HOURGLASS='\xE2\x8C\x9B'

sudo -v

installation_directory=$HOME/updateinstall

echo ""
if [[ -d "$installation_directory" ]]; then
    echo -e "${BLUE}Updating UpdateInstall ...${NC}"
else
    echo -e "${BLUE}Installing UpdateInstall ...${NC}"
fi

mkdir -p "$installation_directory"

echo ""
echo -e "${MAGENTA}Downloading dependencies ...${NC}"
wget -q https://raw.githubusercontent.com/OnCloud125252/Update-Install/main/updateinstall.sh -O "$installation_directory/updateinstall.sh"
echo -e "  ${MAGENTA}${CHECKMARK} updateinstall.sh${NC}"

resources_file="$installation_directory/resources.txt"
if [[ -f "$resources_file" ]]; then
    echo -e "  ${YELLOW}${CROSSMARK} resources.txt (already exists)${NC}"
else
    wget -q https://raw.githubusercontent.com/OnCloud125252/Update-Install/main/resources.txt -O "$resources_file"
    echo -e "  ${MAGENTA}${CHECKMARK} resources.txt${NC}"
fi

chmod +x "$installation_directory/updateinstall.sh"

sudo ln -sf "$installation_directory/updateinstall.sh" /usr/local/bin/updateinstall
sudo ln -sf "$installation_directory/updateinstall.sh" /usr/local/bin/ui

echo ""
if [[ -d "$installation_directory" ]]; then
    echo -e "${GREEN}${ROCKET} UpdateInstall has been updated successfully.${NC}"
else
    echo -e "${GREEN}${ROCKET} UpdateInstall has been installed successfully.${NC}"
fi
