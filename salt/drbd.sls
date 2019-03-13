# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import drbd with context %}
{% from "map.jinja" import network with context %}
{% from "map.jinja" import volumes with context %}
{% set disk = '/dev/{{ volumes.vgname }}/{{ volumes.lvname_drbd }}' %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}

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
      - lvm: Create drbd volume

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

Format drbd:
  pkg.installed:
    - pkgs:
      - e2fsprogs

  blockdev.formatted:
    - name: {{ drbd.device }}
    - fs_type: ext4
    - require:
      - pkg: Format drbd
      - cmd: Sync drbd

Mount drbd:
  mount.mounted:
    - name: /opt
    - device: {{ drbd.device }}
    - fstype: ext4
    - persist: True
    - require:
      - blockdev: Format drbd

{% else %} 

Add drbd to cluster:
  pcs.resource_present:
    - name: drbd__resource_present_{{ drbd.resource }}
    - resource_id: drbd_{{ drbd.resource }}
    - resource_type: ocf:linbit:drbd
    - resource_options:
      - 'drbd_resource={{ drbd.resource }}'
      - 'op'
      - 'monitor'
      - 'interval=60s'
      - '--master'
      - 'master-max=1'
      - 'master-node-max=1'
      - 'clone-max=2'
      - 'clone-node-max=1'
      - 'notify=true'
    - require:
      - cmd: Sync drbd
      - pcs: Setup cluster
{% endif %}
