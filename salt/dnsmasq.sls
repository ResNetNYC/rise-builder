# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import network with context %}
{% set role = salt['environ.get']('RISE_ROLE') %}

Install dnsmasq:
  pkg.installed:
    - pkgs:
      - dnsmasq

Configure dnsmasq:
  file.managed:
    - name: /etc/dnsmasq.conf
    - source: salt://files/dnsmasq.conf.tmpl
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    - defaults:
        fqdn: {{ grains['domain'] }}
        ip: {{ network.primary_address }}
    - require:
      - pkg: Install dnsmasq
      
Primary dnsmasq.conf:
  file.managed:
    - name: /usr/local/share/dnsmasq.conf.primary
    - source: salt://files/dnsmasq.conf.tmpl
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    - defaults:
        fqdn: {{ grains['domain'] }}
        ip: {{ network.primary_address }}
    - require:
      - pkg: Install dnsmasq

Secondary dnsmasq.conf:
  file.managed:
    - name: /usr/local/share/dnsmasq.conf.secondary
    - source: salt://files/dnsmasq.conf.tmpl
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    - defaults:
        fqdn: {{ grains['domain'] }}
        ip: {{ network.secondary_address }}
    - require:
      - pkg: Install dnsmasq

Restart dnsmasq:
  service.running:
    - name: dnsmasq
    - enable: True
    - watch:
      - file: Configure dnsmasq
