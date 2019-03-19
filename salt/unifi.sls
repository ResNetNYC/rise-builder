# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import unifi with context %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}

Unifi directory:
  file.directory:
    - name: /opt/pwm
    - makedirs: True
    - user: 999
    - group: 999
{% if role == 'primary' %}
    - require:
      - mount: Mount drbd
{% endif %}

Run unifi controller:
  docker_container.running:
    - name: unifi
    - hostname: unifi
    - image: jacobalberty/unifi:5.10
    - restart_policy: unless-stopped
    - log_driver: journald
    - networks:
      - local_network
    - port_bindings:
      - 8080:8080/tcp
      - 8443:8443/tcp
      - 3478:3478/udp
      - 10001:10001/udp
    - binds:
      - /opt/unifi:/unifi:rw
    - environment:
      - TZ: {{ unifi.tz }}
    - require:
      - service: docker
      - docker_network: Docker local network
      - file: Unifi directory

{% if role == 'secondary' %}
Stop unifi on secondary:
  docker_container.stopped:
    - containers:
      - unifi
    - require:
      - docker_container: Run unifi controller
{% endif %}
