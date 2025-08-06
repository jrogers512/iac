#!/usr/bin/env python3

import argparse
import json
import os
import sys
from proxmoxer import ProxmoxAPI
from dotenv import load_dotenv

load_dotenv()

try:
    from proxmoxer import ProxmoxAPI
except ImportError:
    print("Error: proxmoxer library not found.")
    print("Please install it using: pip install proxmoxer")
    sys.exit(1)


def get_proxmox_api(host, user, api_token_id, api_token_secret):
    '''
    Connect to Proxmox API
    '''
    try:
        print(f"Connecting to Proxmox with: host={host}, user={user}, token_name={api_token_id}")
        prox = ProxmoxAPI(host, user=user, token_name=api_token_id, token_value=api_token_secret, verify_ssl=False)
        return prox
    except Exception as e:
        print("Error connecting to Proxmox API: {}".format(e))
        sys.exit(1)


def list_lxc_containers(prox, node_name):
    '''
    List all LXC containers on the Proxmox cluster
    '''
    lxc_containers = []
    for vm in prox.nodes(node_name).lxc.get():
        if vm['type'] == 'lxc':
            lxc_containers.append(vm)
    return lxc_containers


def build_inventory(prox):
    '''
    Build Ansible inventory from Proxmox LXC containers
    '''
    inventory = {
        'all': {
            'hosts': [],
        },
        '_meta': {
            'hostvars': {},
        },
    }

    for node in prox.nodes.get():
        node_name = node['node']
        lxc_containers = list_lxc_containers(prox, node_name)

        for lxc in lxc_containers:
            vmid = str(lxc['vmid'])
            status = lxc['status']

            if status == 'running':
                inventory['all']['hosts'].append(vmid)
                inventory['_meta']['hostvars'][vmid] = {
                    'proxmox_node': node_name,
                    'vmid': vmid,
                }

    return inventory


def main():
    print("PROXMOX_USER:", os.environ.get("PROXMOX_USER"))
    print("PROXMOX_API_TOKEN_ID:", os.environ.get("PROXMOX_API_TOKEN_ID"))

    parser = argparse.ArgumentParser(description='Proxmox LXC dynamic inventory for Ansible')
    parser.add_argument('--list', action='store_true', help='List all LXC containers')
    parser.add_argument('--host', action='store', help='Get all the variables about a specific LXC container')
    args = parser.parse_args()

    # Read Proxmox connection details from environment variables
    proxmox_host = os.environ.get('PROXMOX_HOST')
    proxmox_user = os.environ.get('PROXMOX_USER')
    proxmox_api_token_id = os.environ.get('PROXMOX_API_TOKEN_ID')
    proxmox_api_token_secret = os.environ.get('PROXMOX_API_TOKEN_SECRET')

    if not proxmox_host or not proxmox_user or not proxmox_api_token_id or not proxmox_api_token_secret:
        print("Error: PROXMOX_HOST, PROXMOX_USER, PROXMOX_API_TOKEN_ID, and PROXMOX_API_TOKEN_SECRET environment variables must be set.")
        sys.exit(1)

    prox = get_proxmox_api(proxmox_host, proxmox_user, proxmox_api_token_id, proxmox_api_token_secret)

    if args.list:
        inventory = build_inventory(prox)
        print(json.dumps(inventory, indent=4))
    elif args.host:
        inventory = build_inventory(prox)
        if args.host in inventory['_meta']['hostvars']:
            print(json.dumps(inventory['_meta']['hostvars'][args.host], indent=4))
        else:
            print(json.dumps({}))
    else:
        print("Error: Please specify either --list or --host")
        sys.exit(1)


if __name__ == '__main__':
    main()
