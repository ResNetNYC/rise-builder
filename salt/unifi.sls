# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import unifi with context %}

Unifi repo:
  pkgrepo.managed:
    - humanname: Unifi repo
    - name: deb http://www.ui.com/downloads/unifi/debian stable ubiquiti
    - file: /etc/apt/sources.list.d/100-ubnt-unifi.list
    - gpgcheck: 1
    - key_url: https://dl.ui.com/unifi/unifi-repo.gpg
    - require:
      - pkg: apt_packages
    - require_in:
      - pkg: Unifi package

Unifi pkg:
  pkg.latest:
    - name: unifi
    - refresh: True

Unifi service:
  service.running:
    - name: unifi
    - enable: True
    - require:
      - pkg: Unifi pkg

#Unifi Apache config:
#  apache.configfile:
#    - name: /etc/apache2/sites-available/unifi.conf
#    - config:
#      - Virtualhost:
#          this: 'unifi.{# grains['domain'] }}:80'
#          ServerName:
#            - unifi.{{ grains['domain'] }}
#          Redirect: / https://{{ grains['fqdn'] }}:8443
#      - Virtualhost:
#          this: 'unifi.{{ grains['domain'] }}:8443'
#          ServerName:
#            - unifi.{{ grains['domain'] }}
#          SSLProxyEngine: On
#          ProxyRequests: Off
#          Redirect: / https://{{ grains['fqdn'] }}:8443
#          Location:
#            this: '/'
#            ProxyPreserveHost: On
#            ProxyPass: https://{{ grains['fqdn'] }}:8443
#            ProxyPassReverse: https://{{ grains['fqdn'] #}:8443
#
#Enable unifi site:
#  apache_site.enable:
#    - name: unifi.conf
