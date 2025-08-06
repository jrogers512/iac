
# Home Lab IaC

My personal home lab configuration.  Shouldn't be useful for anyone but myself.

## Initial Setup

In the event of complete disaster, you will need to do the following.

### Proxmox

Install proxmox, cluster it.  

Set up terraform credentials in proxmox:

``` shell
# Create user
sudo pveum user add terraform@pve

# Create role with required privileges
sudo pveum role add Terraform -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Datastore.AllocateSpace Pool.Allocate SDN.Use Sys.Audit Sys.Console Sys.Modify Sys.PowerMgmt VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt"

> Todo: figure out cli for adding the `TerraformAPI` pool, assigning it API permission with Terraform role, and putting the command(s) here.

# Assign role to user at root scope
sudo pveum aclmod / -user terraform@pve -role TerraformProvision

# Create API token
sudo pveum user token add terraform@pve terraform-token --privsep=0
```

### Run Terraform

```
cd terraform
terraform init
terraform apply -auto-approve -var="pm_token_secret=$TF_VAR_PM_TOKEN_SECRET" -var="lxc_root=$TF_VAR_LXC_ROOT"
```

## Ansible

We'll use the community.general.proxmox module to create a dynamic inventory of LXC/VM's in Proxmox.  Ultimately, we'll all guests will be defined in ansible and stored as code.  Credentials should be stored in [.env].
