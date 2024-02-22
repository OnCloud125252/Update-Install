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

installation_directory=$HOME/updateinstall
resources_file=$HOME/updateinstall/resources.txt
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
  echo ""
  local new_pid=$(pgrep "$app_name")
  if [ -n "$new_pid" ]; then
    echo -e "${GREEN}${CHECKMARK} Application '$app_name' has been started.${NC}"
  else
    echo -e "${RED}${CROSSMARK} Failed to start application '$app_name'.${NC}"
    return 1
  fi
}

self_update() {
  new_version_file="$installation_directory/updateinstall.sh.new"

  echo ""
  echo -e "${BLUE}Updating UpdateInstall ...${NC}"

  echo ""
  wget --no-cache -q --show-progress -O "$new_version_file" "$self_update_url" || handle_error 1 "Failed to download the update."

  mv -f "$new_version_file" "$installation_directory/updateinstall.sh" >/dev/null 2>&1

  chmod +x "$0"

  echo ""
  echo -e "${GREEN}${CHECKMARK} UpdateInstall updated successfully.${NC}"
  exit 0
}

install_app() {
  app_name=$1
  option=$2
  restart=$3

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
  temp_app_path="$app_path.temp"

  if [ -f "$app_path" ] && [ "$option" != "-f" ]; then
    echo -e "${BLUE}Cache found, installing from cached $app_path ...${NC}"
  else
    if [ "$option" == "-f" ]; then
      echo -e "${YELLOW}User has bypassed cache checking.${NC}"
      echo -e "${BLUE}Downloading resources from remote ...${NC}"
    else
      echo -e "${BLUE}Cache not found, downloading resources from remote ...${NC}"
    fi
    echo ""
    wget --no-cache -c --show-progress -O "$temp_app_path" "$download_url"
    if [ $? -ne 0 ]; then
      handle_error 1 "Failed to download the application."
    fi
    mv "$temp_app_path" "$app_path" >/dev/null 2>&1
    echo -e "${BLUE}Download complete, installing from downloaded $app_path ...${NC}"
  fi
  echo ""
  sudo dpkg -i "$app_path" || handle_error 1 "Failed to install the application."
  package_name=$(dpkg --info "$app_path" | grep -oP "(?<=Package: ).*")

  if [ "$restart" != "norestart" ]; then
    echo ""
    echo -e "${YELLOW}Do you want to restart $package_name?${NC}"
    read -p "(y/N): " restart
    echo ""
    if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
      restart_app "$package_name"
      echo -e "${GREEN}${CHECKMARK} Installation of $package_name completed.${NC}"
    else
      echo -e "${GREEN}${CHECKMARK} Installation of $package_name completed without restart.${NC}"
    fi
  else
    echo ""
    echo -e "${GREEN}${CHECKMARK} Installation of $package_name completed without restart.${NC}"
  fi
}

update_all_apps() {
  echo -e "${YELLOW}Ignoring all cache. No applications will be restarted automatically.${NC}"

  declare -A download_urls
  while IFS='=' read -r key value; do
    download_urls["$key"]="$value"
  done <"$resources_file"

  for app_name in "${!download_urls[@]}"; do
    echo ""
    echo -e "${BLUE}Updating $app_name ...${NC}"
    install_app "$app_name" "-f" "norestart"
  done

  echo ""
  echo -e "${GREEN}${CHECKMARK} All applications have been updated.${NC}"
  echo -e "${YELLOW}You may need to manually restart the updated applications.${NC}"
}

install_vencord() {
  sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)" || handle_error 1 "Failed to download Vencord."
}

update_resources() {
  echo -e "${BLUE}Updating resources file ...${NC}"

  echo ""
  echo -e "${YELLOW}This action WILL REPLACE the current resources file in $installation_directory. Are you sure you want to continue?${NC}"
  read -p "(y/n): " confirm
  echo ""
  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    wget --no-cache -q https://raw.githubusercontent.com/OnCloud125252/Update-Install/main/resources.txt -O "$resources_file" || handle_error 1 "Failed to update the resources file."
    echo -e "${GREEN}${CHECKMARK} Resources file updated successfully.${NC}"
  else
    echo -e "${YELLOW}Update canceled.${NC}"
    return
  fi
}

if [ -z "$1" ]; then
  handle_error 1 "Please provide an application name."
fi

if [[ ! -f "$resources_file" ]]; then
  handle_error 1 "Resources file does not exist.\n  Use \"wget -qO- https://short.on-cloud.tw/UpdateInstall | bash\" to reinstall UpdateInstall."
fi

# Check if the last two bytes of the file are newline characters
last_two_bytes=$(tail -c 2 "$resources_file" | od -An -tx1)
if [[ $last_two_bytes != *"0a"* ]]; then
  # Add a newline to the file
  echo >>"$resources_file"
fi

while IFS='=' read -r key value; do
  if [ "$key" = "update" ]; then
    handle_error 1 "Can't use 'update' as an app name in the resources file."
  fi
  if [ "$key" = "updateall" ]; then
    handle_error 1 "Can't use 'updateall' as an app name in the resources file."
  fi
  if [ "$key" = "vencord" ]; then
    handle_error 1 "'Vencord' is already included in the script, use 'updateinstall vencord' to download it."
  fi
  if [ "$key" = "updateresources" ]; then
    handle_error 1 "Can't use 'updateresources' as an app name in the resources file."
  fi
done <"$resources_file"

sudo -v || handle_error 1 "Failed to acquire sudo privileges."

which curl &>/dev/null || sudo apt install curl

if [ "$1" = "updateall" ]; then
  if [ $# -ne 1 ]; then
    handle_error 1 "No arguments are allowed for the 'updateall' command."
  fi
  update_all_apps
  exit 0
elif [ "$1" = "update" ]; then
  if [ $# -ne 1 ]; then
    handle_error 1 "No arguments are allowed for the 'update' command."
  fi
  self_update
elif [ "$1" = "vencord" ]; then
  if [ $# -ne 1 ]; then
    handle_error 1 "No arguments are allowed for the 'vencord' command."
  fi
  install_vencord
elif [ "$1" = "updateresources" ]; then
  if [ $# -ne 1 ]; then
    handle_error 1 "No arguments are allowed for the 'updateresources' command."
  fi
  update_resources
else
  app_name=$1
  option=$2

  valid_options=("" "-f")

  # Check if the option is valid
  if [[ ! " ${valid_options[@]} " =~ " $option " ]]; then
    handle_error 1 "Invalid option: $option"
  fi

  install_app "$app_name" "$option"
fi
