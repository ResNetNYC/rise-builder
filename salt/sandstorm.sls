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
    - enable: True
    - watch:
      - file: Configure sandstorm
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
