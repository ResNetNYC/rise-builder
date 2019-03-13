# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import volumes with context %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}
{% set disk = 'volumes['vgname']/volumes['lvname_backups']' %}

Format backups:
  pkg.installed:
    - pkgs:
      - e2fsprogs

  blockdev.formatted:
    - name: /dev/{{ disk }}
    - fs_type: ext4
    - require:
      - pkg: Format backups

Mount backups:
  mount.mounted:
    - name: /mnt/backups
    - device: /dev/{{ disk }}
    - fstype: ext4
    - persist: True
    - require:
      - blockdev: Format backups

Install rsnapshot:
  pkg.installed:
    - pkgs:
      - rsnapshot
      - rsync

Configure rsnapshot:
  file.managed:
    - name: /etc/rsnapshot.conf
    - source: salt://files/rsnapshot.conf.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - defaults:
        backup_volume: {{ disk }}

Install rsnapshot unit:
  file.managed:
    - name: /etc/systemd/system/rsnapshot.service
    - source: salt://files/rsnapshot.service
    - user: root
    - group: root
    - mode: 0644
    
Install rsnapshot timer:
  file.managed:
    - name: /etc/systemd/system/rsnapshot.timer
    - source: salt://files/rsnapshot.timer
    - user: root
    - group: root
    - mode: 0644

  service.running:
    - name rsnapshot.timer
    - enable: true
    - require:
      - file: Install rsnapshot unit
      - file: Install rsnapshot timer

{% if role == 'primary' %}
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
    - name rsyncd
    - enable: true
    - require:
      - file: Configure rsyncd
{% endif %}


