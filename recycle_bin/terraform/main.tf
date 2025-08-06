terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = ">= 2.9"
    }
  }
  required_version = ">= 0.13"
}
provider "proxmox" {
  pm_api_url          = "https://192.168.1.5:8006/api2/json"
  pm_api_token_id     = "terraform@pve!terraform-token"
  pm_api_token_secret = var.pm_token_secret
  pm_tls_insecure     = true
}


resource "proxmox_lxc" "immich" {
  vmid         = 936
  hostname     = "immich"
  target_node  = "pve1"
  # ostemplate   = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  ostemplate = "NAS:vztmpl/josh.tar.zst"
  password     = var.lxc_root
  memory       = 4096
  cores        = 4
  pool         = "TerraformAPI"

  rootfs {
    storage = "NAS"
    size    = "8G"
  }

  network {
    name    = "eth0"
    bridge  = "vmbr0"
    ip      = "192.168.1.36/24"
    gw = "192.168.1.1"
  }

  start = true
  unprivileged = true
}

resource "proxmox_lxc" "llm-proxy" {
  vmid         = 937
  hostname     = "llm-proxy"
  target_node  = "pve2"
  # ostemplate   = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  ostemplate = "NAS:vztmpl/josh.tar.zst"
  password     = var.lxc_root
  memory       = 4096
  cores        = 4
  pool         = "TerraformAPI"

  rootfs {
    storage = "NAS"
    size    = "8G"
  }

  network {
    name    = "eth0"
    bridge  = "vmbr0"
    ip      = "192.168.1.37/24"
    gw = "192.168.1.1"
  }

  start = true
  unprivileged = true
}
