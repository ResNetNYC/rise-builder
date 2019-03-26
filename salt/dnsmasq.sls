# -*- coding: utf-8 -*-
# vim: ft=sls

{% set hostname = salt['environ.get']('RISE_HOSTNAME') %}
{% set domain = salt['environ.get']('RISE_DOMAIN') %}
{% set public_ip = salt['environ.get']('RISE_PUBLIC_IP') %}

Install dnsmasq:
  pkg.installed:
    pkgs:
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
        fqdn: {{ hostname }}.{{ domain }}
        ip: {{ public_ip }}
    - require:
      - pkg: Install dnsmasq

Restart dnsmasq:
  service.running:
    - name: dnsmasq
    - enable: True
    - watch:
      - file: Configure dnsmasq
