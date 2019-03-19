# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import volumes with context %}
{% from "map.jinja" import drbd with context %}
{% set lvsize_drbd = salt['environ.get']('RISE_VOLUME_SIZE', volumes.lvsize_drbd) %}
{% set lvsize_backups = salt['environ.get']('RISE_BACKUPS_SIZE', volumes.lvsize_backups) %}

Use disk:
  lvm.pv_present:
    - name: {{ drbd.device }}

Create volume group:
  lvm.vg_present:
    - name: {{ volumes.vgname }}
    - devices: {{ disk }}

Create drbd volume:
  lvm.lv_present:
    - name: {{ volumes.lvname_drbd }}
    - vgname: {{ volumes.vgname }}
    - size: {{ lvsize_drbd }}

Create backups volume:
  lvm.lv_present:
    - name: {{ volumes.lvname_backups }}
    - vgname: {{ volumes.vgname }}
    - size: {{ lvsize_backups }}

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
    - device: {{ drbd.device }}
    - fstype: ext4
    - persist: True
    - require:
      - blockdev: Format drbd
