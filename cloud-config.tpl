#cloud-config
users:
  - name: ${vm_user}
    ssh-authorized-keys:
      - ${ssh_public_key}
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    %{ if use_password }
    passwd: "${vm_password}"
    %{ endif }
    lock_passwd: false
hostname: ${vm_name}
manage_etc_hosts: true
