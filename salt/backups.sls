# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import volumes with context %}
{% from "map.jinja" import network with context %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}
{% set disk = salt['environ.get']('RISE_DISK') %}
{% set backup_disk = salt['environ.get']('RISE_BACKUP_DISK') %}

Format backups:
  pkg.installed:
    - pkgs:
      - e2fsprogs

  blockdev.formatted:
    - name: {{ backup_disk }}
    - fs_type: ext4
    - require:
      - pkg: Format backups

Mount backups:
  mount.mounted:
    - name: /mnt/backups
    - device: {{ backup_disk }}
    - fstype: ext4
    - persist: True
    - mkmnt: True
    - require:
      - blockdev: Format backups

Install rsnapshot:
  pkg.installed:
    - pkgs:
      - rsnapshot
      - rsync

{% if role == 'primary' %}
Configure rsnapshot:
  file.managed:
    - name: /etc/rsnapshot.conf
    - source: salt://files/rsnapshot.conf.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - defaults:
        backup_volume: {{ volumes.vgname }}/{{ volumes.lvname_drbd }}

Install rsnapshot unit:
  file.managed:
    - name: /etc/systemd/system/rsnapshot@.service
    - source: salt://files/rsnapshot@.service
    - user: root
    - group: root
    - mode: 0644
    
Install rsnapshot timer:
  file.managed:
    - name: /etc/systemd/system/rsnapshot-nightly.timer
    - source: salt://files/rsnapshot-nightly.timer
    - user: root
    - group: root
    - mode: 0644

  service.running:
    - name: rsnapshot-nightly.timer
    - enable: true
    - require:
      - file: Install rsnapshot unit
      - file: Install rsnapshot timer

Configure rsyncd:
  file.managed:
    - name: /etc/rsyncd.conf
    - source: salt://files/rsyncd.conf.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - defaults:
        bind_address: {{ network.primary_address }}
    - require:
      - network: Configure cluster network

Run rsyncd:
  service.running:
    - name: rsync
    - enable: true
    - require:
      - file: Configure rsyncd

{% else %}
Install rsync unit:
  file.managed:
    - name: /etc/systemd/system/rsync-backups.service
    - source: salt://files/rsync-backups.service
    - user: root
    - group: root
    - mode: 0644
    
Install rsync timer:
  file.managed:
    - name: /etc/systemd/system/rsync-backups.timer
    - source: salt://files/rsync-backups.timer
    - user: root
    - group: root
    - mode: 0644

  service.running:
    - name: rsync-backups.timer
    - enable: true
    - require:
      - file: Install rsync unit
      - file: Install rsync timer

{% endif %}


