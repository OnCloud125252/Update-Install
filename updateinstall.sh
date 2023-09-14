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

resources_file=$HOME/resources.txt

install_app() {
    app_name=$1

    declare -A download_urls
    while IFS='=' read -r key value; do
        download_urls["$key"]="$value"
    done <"$resources_file"

    if [[ -n ${download_urls["$app_name"]} ]]; then
        download_url=${download_urls["$app_name"]}
    else
        echo -e "${GREEN}${CHECKMARK} Unknown application: $app_name${NC}"
        exit 1
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
    sudo dpkg -i "$app_path"
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
    sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)"
}

if [ -z "$1" ]; then
    echo -e "${RED}${CROSSMARK} Please provide an application name.${NC}"
    exit 1
fi

if [[ ! -f "$resources_file" ]]; then
    echo -e "${RED}${CROSSMARK} Resources file does not exist.${NC}"
    exit 1
fi

while IFS='=' read -r key value; do
    if [ "$key" == "update" ]; then
        echo -e "${RED}${CROSSMARK} Can't use 'update' as an app name in the resources file.${NC}"
        return 1
    fi
done <"$resources_file"

sudo -v

if [ "$1" = "vencord" ]; then
    install_vencord
else
    app_name=$1
    install_app "$app_name"
fi
