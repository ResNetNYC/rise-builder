# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import volumes with context %}
{% set disk = salt['environ.get']('RISE_DISK') %}
{% set lvsize_drbd = salt['environ.get']('RISE_VOLUME_SIZE', volumes.lvsize_drbd) %}
{% set lvsize_backups = salt['environ.get']('RISE_BACKUPS_SIZE', volumes.lvsize_backups) %}

Use disk:
  lvm.pv_present:
    - name: {{ disk }}

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
