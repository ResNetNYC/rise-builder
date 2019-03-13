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

Set hacluster user password:
  user.present:
    - name: {{ pcs.user }}
    - system: True
    - password: {{ pcs.password }}

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

Setup cluster:
  pcs.cluster_setup:
    - name: pcs_setup__setup
    - nodes:
      - primary
      - secondary
    - pcsuser: {{ pcs.user }}
    - pcspasswd: {{ pcs.password }}
    - extra_args:
      - '--start'
      - '--enable'
    - require:
      - pkg: Install cluster tools
      - service: Start pcsd
      - pcs: Authorize cluster nodes
{% endif %}
