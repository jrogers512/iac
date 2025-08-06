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
  local host_config=$(yq ".hosts.\"$host_name\"" ${0%/*}/hosts-config.yaml)

  if [ -z "$host_config" ]; then
    echo "Error: Host '$host_name' not found in ${0%/*}/hosts-config.yaml"
    return 1
  fi

  local url=$(yq ".url" <<< "$host_config")
  local pve=$(yq ".pve" <<< "$host_config")
  local user=$(whoami)
  local root_password=$(yq ".root_password" <<< "$host_config")
  local hostname=$(yq ".hostname" <<< "$host_config")
  local disk_size=$(yq ".disk_size" <<< "$host_config")
  local cpu_cores=$(yq ".cpu_cores" <<< "$host_config")
  local ram_size=$(yq ".ram_size" <<< "$host_config")```shell
phs/remote-deploy.sh
```

  local static_ip=$(yq ".static_ip" <<< "$host_config")
  local gateway=$(yq ".gateway" <<< "$host_config")

  echo "Deploying host: $host_name on PVE: $pve"

  # Download the community script
  echo "Downloading community script from $url"
  curl -sSL "$url" -o /tmp/community_script.sh

  # Set variables and Bypass interactive functions
  sed -i "s/variables()/variables(){\n CT_TYPE=1\n PW='$root_password'\n HN='$hostname'\n DISK_SIZE='$disk_size'\n CORE_COUNT='$cpu_cores'\n RAM_SIZE='$ram_size'\n NET='$static_ip'\n GATE='$gateway'\n DIAGNOSTICS='no'\n}/g" /tmp/community_script.sh
  sed -i 's/ssh_check()/ #ssh_check()/g' /tmp/community_script.sh
  sed -i 's/write_config()/ #write_config()/g' /tmp/community_script.sh
  sed -i 's/advanced_settings()/ #advanced_settings()/g' /tmp/community_script.sh
  sed -i 's/diagnostics_check()/ #diagnostics_check()/g' /tmp/community_script.sh
  sed -i 's/install_script()/ #install_script()/g' /tmp/community_script.sh

  # Copy the script to the Proxmox VE node
  echo "Copying script to $user@$pve:/tmp/community_script.sh"
  scp /tmp/community_script.sh "$user@$pve:/tmp/community_script.sh"

  # Execute the script on the Proxmox VE node
  echo "Executing script on $pve"
  ssh "$user@$pve" "sudo bash /tmp/community_script.sh"

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
    deploy_host "$host_name"
  done
fi

echo "Finished deploying all specified hosts"
