# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import pwm with context %}
{% set admin_password = salt['environ.get']('RISE_ADMIN_PASSWORD') %}
{% set sandstorm_password = salt['environ.get']('RISE_SANDSTORM_PASSWORD') %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}
{% set fqdn = grains['fqdn'] %}

Ldap config directory:
  file.directory:
    - name: /opt/ldap/config
    - makedirs: True
    - user: nobody
    - group: nogroup
{% if role == 'primary' %}
    - require:
      - mount: Mount drbd
{% endif %}

Ldap data directory:
  file.directory:
    - name: /opt/ldap/data
    - makedirs: True
    - user: nobody
    - group: nogroup
{% if role == 'primary' %}
    - require:
      - mount: Mount drbd
{% endif %}

Seed ldif files:
  file.recurse:
    - name: /opt/ldap/ldif
    - source: salt://files/ldif
    - makedirs: True
    - user: nobody
    - group: nogroup
{% if role == 'primary' %}
    - require:
      - mount: Mount drbd
{% endif %}

Docker local network:
  docker_network.present:
    - name: local_network
    - driver: bridge
    - require:
      - service: docker

Run ldap:
  docker_container.running:
    - name: ldap
    - hostname: ldap
    - image: osixia/openldap:1.2.4
    - restart_policy: unless-stopped
    - log_driver: journald
    - networks:
      - local_network
    - port_bindings:
      - 127.0.0.1:389:389
      - 127.0.0.1:636:636
    - binds:
      - /opt/ldap/config:/etc/ldap/slapd.d:rw
      - /opt/ldap/data:/var/lib/ldap:rw
      - /opt/ldap/ldif:/container/service/slapd/assets/config/bootstrap/ldif/custom:ro
    - environment:
      - LDAP_ORGANISATION: RISE
      - LDAP_DOMAIN: rise-nyc.com
      - LDAP_ADMIN_PASSWORD: {{ admin_password }}
      - LDAP_READONLY_USER: true
      - LDAP_READONLY_USER_USERNAME: sandstorm
      - LDAP_READONLY_USER_PASSWORD: {{ sandstorm_password }}
      - LDAP_OPENLDAP_UID: 65534
      - LDAP_OPENLDAP_GID: 65534
      - LDAP_TLS: false
    - command: --copy-service
    - require:
      - service: docker
      - docker_network: Docker local network
      - file: Ldap config directory
      - file: Ldap data directory
      - file: Seed ldif files

Pwm directory:
  file.directory:
    - name: /opt/pwm
    - makedirs: True
    - user: 1234
    - group: 1234
{% if role == 'primary' %}
    - require:
      - mount: Mount drbd
{% endif %}

{% if role == 'primary' %}
Pwm config:
  file.managed:
    - name: /opt/pwm/PwmConfiguration.xml
    - source: salt://files/PwmConfiguration.xml.tmpl
    - user: 1234
    - group: 1234
    - mode: 0644
    - template: jinja
    - defaults:
        admin_password: {{ admin_password }}
        admin_hash: {{ salt['bhash.hash'](admin_password) }}
        security_key: '{{ salt['grains.get_or_set_hash']('pwm:securityKey', length=64, chars='abcdefghijklmnopqrstuvwxyz0123456789') }}'
        fqdn: {{ fqdn }}
    - require:
      - file: Pwm directory
{% endif %}

Run pwm:
  docker_container.running:
    - name: pwm
    - hostname: pwm
    - image: fjudith/pwm:latest
    - restart_policy: unless-stopped
    - log_driver: journald
    - networks:
      - local_network
    - port_bindings:
      - 8081:8080/tcp
    - binds:
      - /opt/pwm:/usr/share/pwm:rw
    - require:
      - service: docker
      - docker_network: Docker local network
{% if role == 'primary' %}
      - file: Pwm config
{% endif %}
      - file: Pwm directory

{% if role == 'secondary' %}
Stop on secondary:
  docker_container.stopped:
    - containers:
      - ldap
      - pwm
    - require:
      - docker_container: Run pwm
      - docker_container: Run ldap
{% endif %}
