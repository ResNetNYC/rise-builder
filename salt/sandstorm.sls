# -*- coding: utf-8 -*-
# vim: ft=sls

{% set fqdn = grains['fqdn'] %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}

{% if role == 'primary' %}
Download sandstorm:
  file.managed:
    - name: /tmp/sandstorm-244.tar.xz
    - source: https://dl.sandstorm.io/sandstorm-244.tar.xz
    - skip_verify: True

Install sandstorm:
  cmd.script:
    - name: install.sh -d -e -i /tmp/sandstorm-244.tar.xz
    - source: https://install.sandstorm.io
    - runas: root
    - creates: /opt/sandstorm/sandstorm.conf
    - env:
      - BASE_URL: http://{{ fqdn }}
    - require:
      - file: Download sandstorm
      - mount: Mount drbd

Configure sandstorm:
  file.managed:
    - name: /opt/sandstorm/sandstorm.conf
    - source: salt://files/sandstorm.conf.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - defaults:
        fqdn: {{ fqdn }}

Restart sandstorm:
  service.running:
    - name: sandstorm
    - enable: False
    - watch:
      - file: Configure sandstorm

Add Sandstorm to cluster:
  pcs.resource_present:
    - name: systemd__resource_present_sandstorm
    - resource_id: sandstorm
    - resource_type: systemd:sandstorm
    - require:
      - pcs: Setup cluster

Sandstorm colocation:
  pcs.constraint_present:
    - name: sandstorm__constraint_present_sandstorm_colocation
    - constraint_id: colocation-sandstorm-fs_r0
    - constraint_type: colocation
    - constraint_options:
      - 'add'
      - 'sandstorm'
      - 'with'
      - 'fs_r0'
    - require:
      - pcs: Add Sandstorm to cluster
      - pcs: Add filesystem to cluster

Sandstorm ordering:
  pcs.constraint_present:
    - name: sandstorm__constraint_present_sandstorm_order
    - constraint_id: order-sandstorm-fs_r0
    - constraint_type: order
    - constraint_options:
      - 'fs_r0'
      - 'then'
      - 'sandstorm'
    - require:
      - pcs: Add Sandstorm to cluster
      - pcs: Add filesystem to cluster

{% else %}
Add sandstorm unit:
  file.managed:
    - name: /etc/systemd/system/sandstorm.service
    - source: salt://files/sandstorm.service
    - user: root
    - group: root
    - mode: 0644

Sandstorm symlink:
  file.symlink:
    - name: /usr/local/bin/sandstorm
    - target: /opt/sandstorm/sandstorm
    - force: True
    - makedirs: True

Spk symlink:
  file.symlink:
    - name: /usr/local/bin/spk
    - target: /opt/sandstorm/sandstorm
    - force: True
    - makedirs: True

Disable sandstorm:
  service.dead:
    - name: sandstorm
    - enable: False
{% endif %}
