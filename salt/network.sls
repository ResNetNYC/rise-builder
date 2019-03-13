# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import network with context %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}
{% set hostname = salt['environ.get']('RISE_HOSTNAME') %}
{% set domain = salt['environ.get']('RISE_DOMAIN') %}

Configure system:
  network.system:
    - enabled: True
    - hostname: {{ hostname }}
    - nisdomain: {{ domain }}
    - apply_hostname: True
    - retain_settings: True

Configure main network:
  network.managed:
    - name: {{ network.main_interface }}
    - type: eth
    - proto: dhcp
    - require:
      - network: Configure system

{% if role == 'primary' %}
Configure cluster network:
  network.managed:
    - name: {{ network.cluster_interface }}
    - type: eth
    - proto: static
    - ipaddr: {{ network.primary_address }}
    - netmask: {{ network.cluster_netmask }}
    - require:
      - network: Configure system

  host.present:
    - ip: {{ network.secondary_address }}
    - names:
      - secondary
      - secondary.{{ domain }}
{% else %}
Configure cluster network:
  network.managed:
    - name: {{ network.cluster_interface }}
    - type: eth
    - proto: static
    - ipaddr: {{ network.secondary_address }}
    - netmask: {{ network.cluster_netmask }}
    - require:
      - network: Configure system

  host.present:
    - ip: {{ network.primary_address }}
    - names:
      - primary
      - primary.{{ domain }}
{% endif %}
