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

    echo ""
    echo -e "${RED}${CROSSMARK} Error: $error_message${NC}"
    exit $exit_code
}

restart_app() {
    local app_name=$1

    echo ""
    echo -e "${MAGENTA}Restarting $app_name...${NC}"

    # Find the PID of the running process based on the application name
    local pid=$(pgrep "$app_name")

    echo ""
    if [ -n "$pid" ]; then
        # Send a termination signal to the process and wait for it to exit
        kill -TERM "$pid"
        wait "$pid"

        # Check if the process has terminated successfully
        if ! kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}${CHECKMARK} Application '$app_name' has been terminated successfully.${NC}"
        else
            echo -e "${RED}${CROSSMARK} Failed to terminate application '$app_name'.${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}No running instance of application '$app_name' found.${NC}"
    fi

    # Start the application in the background using 'nohup'
    nohup "$app_name" >/dev/null 2>&1 &

    # Check if the application has started successfully
    local new_pid=$(pgrep "$app_name")
    if [ -n "$new_pid" ]; then
        echo -e "${GREEN}${CHECKMARK} Application '$app_name' has been started.${NC}"
    else
        echo -e "${RED}${CROSSMARK} Failed to start application '$app_name'.${NC}"
        return 1
    fi
}

self_update() {
    echo ""
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
    bypass_cache=$2

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
    if [ -f "$app_path" ] && [ "$bypass_cache" != "-f" ]; then
        echo -e "${BLUE}Cache found, installing from cached /tmp/$app_filename ...${NC}"
    else
        if [ "$bypass_cache" == "-f" ]; then
            echo -e "${YELLOW}Bypassing cache checking.${NC}"
            echo -e "${BLUE}Downloading resources from remote ...${NC}"
        else
            echo -e "${BLUE}Cache not found, downloading resources from remote ...${NC}"
        fi
        echo ""
        wget -q --show-progress -O "$app_path" "$download_url"
        echo -e "${BLUE}Download complete, installing from downloaded /tmp/$app_filename ...${NC}"
    fi
    echo ""
    sudo dpkg -i "$app_path" || handle_error 1 "Failed to install the application."
    package_name=$(dpkg --info "$app_path" | grep -oP "(?<=Package: ).*")

    echo ""
    echo -e "${YELLOW}Do you want to restart $package_name?${NC}"
    read -p "(y/n): " restart
    if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
        restart_app $package_name
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
    if [ "$key" = "update" ]; then
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
    bypass_cache=$2
    install_app "$app_name" "$bypass_cache"
fi
