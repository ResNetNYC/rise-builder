# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import pcs with context %}
{% set role = salt['environ.get']('RISE_ROLE', 'secondary') %}

Install cluster tools:
  pkg.installed:
    - pkgs:
      - corosync
      - pacemaker
      - pcs
      - psmisc

Stop corosync:
  service.dead:
    - name: corosync

Remove corosync config:
  file.absent:
    - name: /etc/corosync/corosync.conf

Set hacluster user password:
  user.present:
    - name: {{ pcs.user }}
    - system: True
    - password: {{ pcs.password }}
    - hash_password: True

Start pcsd:
  service.running:
    - name: pcsd
    - enable: True
    - require:
      - pkg: Install cluster tools

{% if role == 'primary' %}
Authorize cluster nodes:
  pcs.auth:
    - name: pcs_auth__auth
    - nodes:
      - primary
      - secondary
    - pcsuser: {{ pcs.user }}
    - pcspasswd: {{ pcs.password }}
    - extra_args: []
    - require:
      - network: Configure cluster network
      - pkg: Install cluster tools
      - service: Start pcsd
      - user: Set hacluster user password
      - service: Stop corosync
      - file: Remove corosync config

Setup cluster:
  pcs.cluster_setup:
    - name: pcs_setup__setup
    - pcsclustername: {{ pcs.cluster_name }}
    - nodes:
      - primary
      - secondary
    - extra_args:
      - '--start'
      - '--enable'
      - '--force'
    - require:
      - pkg: Install cluster tools
      - service: Start pcsd
      - pcs: Authorize cluster nodes

Disable stonith:
  pcs.prop_has_value:
    - name: pcs_properties__prop_has_value_stonith-enabled
    - prop: stonith-enabled
    - value: false
    - require:
      - pcs: Setup cluster
{% endif %}
