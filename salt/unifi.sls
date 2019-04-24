# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "map.jinja" import unifi with context %}

Unifi directory:
  file.directory:
    - name: /opt/unifi
    - makedirs: True
    - user: 999
    - group: 999

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

Unifi Apache config:
  apache.configfile:
    - name: /etc/apache2/sites-available/unifi.conf
    - config:
      - Virtualhost:
          this: 'unifi.{{ grains['domain'] }}:80'
          ServerName:
            - unifi.{{ grains['domain'] }}
          Redirect: / https://{{ grains['fqdn'] }}:8443
      - Virtualhost:
          this: 'unifi.{{ grains['domain'] }}:8443'
          ServerName:
            - unifi.{{ grains['domain'] }}
          SSLProxyEngine: On
          ProxyRequests: Off
          Redirect: / https://{{ grains['fqdn'] }}:8443
          Location:
            this: '/'
            ProxyPreserveHost: On
            ProxyPass: https://{{ grains['fqdn'] }}:8443
            ProxyPassReverse: https://{{ grains['fqdn'] }}:8443

Enable unifi site:
  apache_site.enable:
    - name: unifi.conf
