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

resources_file=./resources.txt
self_update_url=https://raw.githubusercontent.com/OnCloud125252/Update-Install/main/updateinstall.sh

handle_error() {
    local exit_code=$1
    local error_message=$2

    echo -e "${RED}${CROSSMARK} Error: $error_message${NC}"
    exit $exit_code
}

self_update() {
    echo -e "${BLUE}Updating UpdateInstall ...${NC}"
    echo ""

    wget -q --show-progress -O "$(basename "$0")" "$self_update_url" || handle_error 1 "Failed to download the update."

    mv "$(basename "$0")" "$0" >/dev/null 2>&1

    chmod +x "$0"

    echo ""
    echo -e "${GREEN}${CHECKMARK} UpdateInstall updated successfully.${NC}"
    exit 0
}

install_app() {
    app_name=$1

    declare -A download_urls
    while IFS='=' read -r key value; do
        download_urls["$key"]="$value"
    done <"$resources_file"

    if [[ -n ${download_urls["$app_name"]} ]]; then
        download_url=${download_urls["$app_name"]}
    else
        handle_error 1 "Unknown application: $app_name"
    fi

    app_filename=$(basename $(curl -L --head -w "%{url_effective}" "$download_url" 2>/dev/null | tail -n1))
    app_path="/tmp/$app_filename"
    if [ -f "$app_path" ]; then
        echo -e "${BLUE}Cache found, installing from cached /tmp/$app_filename ...${NC}"
        echo ""
    else
        echo -e "${BLUE}Cache not found, downloading resources from remote ...${NC}"
        echo ""
        wget -q --show-progress -O "$app_path" "$download_url"
        echo -e "${BLUE}Download complete, installing from downloaded /tmp/$app_filename ...${NC}"
        echo ""
    fi
    sudo dpkg -i "$app_path" || handle_error 1 "Failed to install the application."
    package_name=$(dpkg --info "$app_path" | grep -oP "(?<=Package: ).*")

    echo ""
    echo -e "${YELLOW}Do you want to restart $package_name?${NC}"
    read -p "(y/n): " restart
    echo ""
    if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
        echo -e "${MAGENTA}Restarting $package_name...${NC}"
        pkill -f "$package_name"
        $package_name
        echo ""
        echo -e "${GREEN}${CHECKMARK} Installation of $package_name completed.${NC}"
    else
        echo ""
        echo -e "${GREEN}${CHECKMARK} Installation of $package_name completed without restart.${NC}"
    fi
}

install_vencord() {
    sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)" || handle_error 1 "Failed to download Vencord."
}

if [ -z "$1" ]; then
    handle_error 1 "Please provide an application name."
fi

if [[ ! -f "$resources_file" ]]; then
    handle_error 1 "Resources file does not exist."
fi

while IFS='=' read -r key value; do
    if [ "$key" == "update" ]; then
        echo -e "${RED}${CROSSMARK} Can't use 'update' as an app name in the resources file.${NC}"
        return 1
    fi
done <"$resources_file"

sudo -v || handle_error 1 "Failed to acquire sudo privileges."

if [ "$1" = "update" ]; then
    self_update
elif [ "$1" = "vencord" ]; then
    install_vencord
else
    app_name=$1
    install_app "$app_name"
fi
