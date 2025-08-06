# Proxmox Helper Scripts (PHS)

This directory contains scripts and configuration files for automating the deployment of hosts (both containers and VMs) on Proxmox VE using [community-provided helper scripts](https://community-scripts.github.io/ProxmoxVE) in a Infrastructure as Code (IaC) manner.

## Files

- `hosts-config.yaml`: Configuration file containing parameters for each host to be deployed.
- `remote-deploy.sh`: Wrapper script which logs into the appropriate PVE, downloads the helper script, edits it so that it runs non-interactively, and then executes the helper script on the PVE which creates the new host.

## Usage

1. Edit `hosts-config.yaml` to add or modify host configurations.
2. Run the deployment script with an optional host name as an argument:

   ```bash
   ./remote-deploy.sh [<host-name>]
   ```

   - If no host name is provided, all hosts in the configuration will be deployed.
   - Example for a specific host:

     ```bash
     ./remote-deploy.sh grocy
     ```

## Requirements

- Proxmox VE cluster with access to the API
- SSH access to Proxmox nodes
- `yq` tool for parsing YAML files (will be installed via apt if missing)
- password free ssh authentication as the current user on the Proxmox node (PVE)

## Host Configuration

Each host configuration in `hosts-config.yaml` should include the following parameters:

- `hostname`: Hostname for the host
- `host_id`: Unique identifier for the host
- `root_password`: The su password to use for this host
- `url`: URL to download the Proxmox helper script
- `pve`: Proxmox node IP
- `disk_size`: Disk size in GB
- `cpu_cores`: Number of CPU cores
- `ram_size`: Memory size in MB
- `net_type`: Network type (static or dhcp)
- `static_ip`: Static IP address (if net_type is static)
- `gateway`: Gateway IP address
- `template`: Template to use for host creation

### `hosts-config.yaml` Example

``` yaml
hosts:
  grocy:
    hostname: grocy
    host_id: 939
    root_password: rootpass123
    url: https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/grocy.sh
    pve: 192.168.1.5
    disk_size: 2
    cpu_cores: 2
    ram_size: 512
    net_type: static
    static_ip: 192.168.1.39/24
    gateway: 192.168.1.1
    template: ubuntu-22.04-standard_22.04-1_amd64.tar.zst
```
