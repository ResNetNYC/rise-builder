# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import volumes with context %}
{% from "map.jinja" import network with context %}

Install rsnapshot:
  pkg.installed:
    - pkgs:
      - rsnapshot
      - rsync

Configure rsnapshot:
  file.managed:
    - name: /etc/rsnapshot.conf
    - source: salt://files/rsnapshot.conf.tmpl
    - user: root
    - group: root
    - mode: 0644

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

Run rsyncd:
  service.running:
    - name: rsync
    - enable: true
    - require:
      - file: Configure rsyncd

Install rsync script:
  file.managed:
    - name: /usr/local/sbin/rsync-backups.sh
    - source: salt://files/rsync-backups.sh
    - user: root
    - group: root
    - mode: 0755

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

Install make-primary script:
  file.managed:
    - name: /usr/local/sbin/make-primary.sh
    - source: salt://files/make-primary.sh
    - user: root
    - group: root
    - mode: 0755

Install make-secondary script:
  file.managed:
    - name: /usr/local/sbin/make-secondary.sh
    - source: salt://files/make-secondary.sh
    - user: root
    - group: root
    - mode: 0755
