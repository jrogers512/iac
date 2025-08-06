#!/bin/bash

# Install yq if not already installed
if ! command -v yq &> /dev/null
then
    echo "yq not found, installing..."
    apt-get update && apt-get install -y yq
fi

# Read hosts-config.yaml
if [ ! -f "${0%/*}/hosts-config.yaml" ]; then
  echo "Error: ${0%/*}/hosts-config.yaml not found"
  exit 1
fi

# Function to deploy a single host
deploy_host() {
  local host_name="$1"
  local host_config=$(yq ".hosts.\"${host_name}\"" ${0%/*}/hosts-config.yaml)

  if [ -z "$host_config" ]; then
    echo "Error: Host '$host_name' not found in ${0%/*}/hosts-config.yaml"
    return 1
  fi

  url=$(yq ".url" <<< "$host_config" 2>/dev/null | tr -d \")
  pve=$(yq ".pve" <<< "$host_config" 2>/dev/null | tr -d \")
  user=$(whoami)
  root_password=$(yq ".root_password" <<< "$host_config" 2>/dev/null | tr -d \")
  hostname=$(yq ".hostname" <<< "$host_config" 2>/dev/null | tr -d \")
  disk_size=$(yq ".disk_size" <<< "$host_config" 2>/dev/null | tr -d \")
  cpu_cores=$(yq ".cpu_cores" <<< "$host_config" 2>/dev/null | tr -d \")
  ram_size=$(yq ".ram_size" <<< "$host_config" 2>/dev/null | tr -d \")
  static_ip=$(yq ".static_ip" <<< "$host_config")
  gateway=$(yq ".gateway" <<< "$host_config")

  if [ -z "$url" ] || [ -z "$pve" ] || [ -z "$root_password" ] || [ -z "$hostname" ] || [ -z "$disk_size" ] || [ -z "$cpu_cores" ] || [ -z "$ram_size" ]; then
    echo "Error: Missing required configuration for host '$host_name'"
    return 1
  fi

  echo "Deploying host: $host_name on PVE: $pve"

  echo "URL: $url"
  echo "root_password: $root_password"
  echo "hostname: $hostname"
  echo "disk_size: $disk_size"
  echo "cpu_cores: $cpu_cores"
  echo "ram_size: $ram_size"

  # Download the community script
  echo "Downloading community script from $url"
  curl -sSL "$url" -o /tmp/community_script.sh

  # Download build.func
  build_func_url="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func"
  echo "Downloading build.func from $build_func_url"
  curl -sSL "$build_func_url" -o /tmp/build.func

  # Bypass interactive functions in build.func
  sed -i 's/ssh_check()/ssh_check() { return; }/g' /tmp/build.func
  sed -i 's/write_config()/write_config() { :; }/g' /tmp/build.func
  sed -i 's/advanced_settings()/advanced_settings() { :; }/g' /tmp/build.func
  sed -i 's/diagnostics_check()/diagnostics_check() { :; }/g' /tmp/build.func
  sed -i 's/install_script()/install_script() { :; }/g' /tmp/build.func

  # Copy the scripts to the Proxmox VE node
  echo "Copying scripts to $user@$pve:/tmp/"
  scp /tmp/community_script.sh /tmp/custom_build.func "$user@$pve:/tmp/"

  # Execute the script on the Proxmox VE node
  echo "Executing script on $pve"
  ssh "$user@$pve" "source /tmp/custom_build.func; CT_TYPE=1 PW=\"$root_password\" HN=\"$hostname\" DISK_SIZE=$disk_size CORE_COUNT=$cpu_cores RAM_SIZE=$ram_size NET=\"$static_ip\" GATE=\"$gateway\" DIAGNOSTICS=no sudo bash /tmp/community_script.sh"

  echo "Finished deploying $host_name on $pve"
}

# Handle hostname argument
if [ -n "$1" ]; then
  # Deploy a single host
  deploy_host "$1"
else
  # Deploy all hosts
  echo "No host specified, deploying all hosts from ${0%/*}/hosts-config.yaml"
  host_names=$(yq ".hosts | keys | .[]" ${0%/*}/hosts-config.yaml)
  for host_name in $host_names; do
    deploy_host "${host_name//\"/}"
  done
fi

echo "Finished deploying all specified hosts"
