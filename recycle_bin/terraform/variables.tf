variable "pm_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "lxc_root" {
  description = "LXC root password"
  type        = string
  sensitive   = true
}
