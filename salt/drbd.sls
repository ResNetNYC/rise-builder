# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import drbd with context %}
{% from "map.jinja" import network with context %}
{% from "map.jinja" import volumes with context %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}
{% set disk = salt['environ.get']('RISE_DISK') %}

Install drbd:
  pkg.installed:
    - pkgs:
      - drbd-utils

  file.managed:
    - name: /etc/drbd.d/{{ drbd.resource }}.res
    - source: salt://files/drbd-resource.template
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - defaults:
        resource: {{ drbd.resource }}
        device: {{ drbd.device }}
        disk: {{ disk }}
        primary_address: {{ network.primary_address }}
        secondary_address: {{ network.secondary_address }}
        port: {{ drbd.port }}
    - require:
      - pkg: Install drbd
  
Create drbd:
  cmd.run:
    - name: drbdmeta --force 0 v08 {{ disk }} internal create-md
    - runas: root
    - creates: {{ drbd.device }}
    - require:
      - file: Install drbd

Start drbd:
  cmd.run:
    - name: drbdadm up {{ drbd.resource }}
    - runas: root
    - creates: {{ drbd.device }}
    - require:
      - cmd: Create drbd

{% if role == 'primary' %}
Sync drbd:
  cmd.run:
    - name: drbdadm primary --force {{ drbd.resource }}
    - runas: root
    - require:
      - cmd: Start drbd

Use disk:
  lvm.pv_present:
    - name: {{ drbd.device }}
    - require:
      - cmd: Start drbd

Create volume group:
  lvm.vg_present:
    - name: {{ volumes.vgname }}
    - devices: {{ drbd.device }}
    - require:
      - lvm: Use disk

Create drbd volume:
  lvm.lv_present:
    - name: {{ volumes.lvname_drbd }}
    - vgname: {{ volumes.vgname }}
    - extents: 90%VG
    - require:
      - lvm: Create volume group

Format disk:
  pkg.installed:
    - pkgs:
      - e2fsprogs

  blockdev.formatted:
    - name: /dev/{{ volumes.vgname }}/{{ volumes.lvname_drbd }}
    - fs_type: ext4
    - require:
      - pkg: Format disk
      - cmd: Sync drbd

Mount drbd:
  mount.mounted:
    - name: /opt
    - device: /dev/{{ volumes.vgname }}/{{ volumes.lvname_drbd }}
    - fstype: ext4
    - persist: False
    - require:
      - blockdev: Format disk

Add drbd to cluster:
  pcs.resource_present:
    - name: drbd__resource_present_{{ drbd.resource }}
    - resource_id: drbd_{{ drbd.resource }}
    - resource_type: ocf:linbit:drbd
    - resource_options:
      - 'drbd_resource={{ drbd.resource }}'
      - 'ignore_missing_notifications=true'
      - 'op'
      - 'monitor'
      - 'interval=60s'
      - '--master'
    - require:
      - cmd: Sync drbd
      - pcs: Setup cluster

Add filesystem to cluster:
  pcs.resource_present:
    - name: fs__resource_present_{{ drbd.resource }}
    - resource_id: fs_{{ drbd.resource }}
    - resource_type: ocf:heartbeat:Filesystem
    - resource_options:
      - 'device=/dev/{{ volumes.vgname }}/{{ volumes.lvname_drbd }}'
      - 'directory=/opt'
      - 'fstype=ext4'
    - require:
      - cmd: Sync drbd
      - pcs: Setup cluster

Filesystem colocation:
  pcs.constraint_present:
    - name: drbd__constraint_present_fs_{{ drbd.resource }}_colocation
    - constraint_id: colocation-fs_{{ drbd.resource }}-drbd
    - constraint_type: colocation
    - constraint_options:
      - 'add'
      - 'fs_{{ drbd.resource }}'
      - 'with'
      - 'drbd_{{ drbd.resource }}-master'
    - require:
      - pcs: Add filesystem to cluster
      - pcs: Add drbd to cluster

Filesystem ordering:
  pcs.constraint_present:
    - name: drbd__constraint_present_fs_{{ drbd.resource }}_order
    - constraint_id: order-fs_{{ drbd.resource }}-drbd
    - constraint_type: order
    - constraint_options:
      - 'promote'
      - 'drbd_{{ drbd.resource }}-master'
      - 'then'
      - 'start'
      - 'fs_{{ drbd.resource }}'
    - require:
      - pcs: Add filesystem to cluster
      - pcs: Add drbd to cluster
{% endif %}
