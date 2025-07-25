# iac

My home lab configuration.  Nothing really to see here.

# Playbooks

## Proxmox

Proxmox labels should reflect categories that can be used in ansible inventory:
- __Operating System:__

  - `debian`: For all Debian-based OSs (e.g., Debian, Ubuntu). This will allow you to use `apt upgrade` to bulk update them.
  - `centos`: For all CentOS-based OSs.
  - `windows`: For all Windows-based VMs.
  - `other_os`: For any other operating systems.

- __Network Exposure:__

  - `internal_only`: For VMs and LXCs that are only accessible from within your internal network.
  - `public_facing`: For VMs and LXCs that are directly accessible from the internet.

- __Function/Application:__

  - `web_server`: For VMs and LXCs that are running web servers (e.g., Apache, Nginx).
  - `database_server`: For VMs and LXCs that are running database servers (e.g., MySQL, PostgreSQL).
  - `application_server`: For VMs and LXCs that are running application servers (e.g., Tomcat, JBoss).
  - `other_app`: For any other applications.

- __Environment:__

  - `development`: For VMs and LXCs used for development purposes.
  - `staging`: For VMs and LXCs used for staging purposes.
  - `production`: For VMs and LXCs used for production purposes.


- Generate inventory for proxmox.
  - [[playbooks/prox_generate_inventory.yml]]
  - [[scripts/prox_generate_inventory.py]]

