# -*- coding: utf-8 -*-
# vim: ft=sls

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
      - BASE_URL: http://{{ grains['domain'] }}
    - require:
      - file: Download sandstorm

Configure sandstorm:
  file.managed:
    - name: /opt/sandstorm/sandstorm.conf
    - source: salt://files/sandstorm.conf.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - defaults:
        fqdn: {{ grains['domain'] }}

Restart sandstorm:
  service.running:
    - name: sandstorm
    - enable: True
    - watch:
      - file: Configure sandstorm

#Sandstorm Apache config:
  #  apache.configfile:
  #    - name: /etc/apache2/sites-available/000-sandstorm.conf
  #    - config:
  #      - Virtualhost:
  #          this: '*:80'
  #          ServerName:
  #            - {# grains['domain'] }}
  #          ServerAlias:
  #            - *.{{ grains['domain'] }}
  #          Location:
  #            this: '/'
  #            ProxyPreserveHost: On
  #            ProxyPass: http://{{ grains['fqdn'] }}:8080
  #            ProxyPassReverse: http://{{ grains['fqdn'] #}:8080
  #
  #Enable Sandstorm site:
  #  apache_site.enable:
  #    - name: 000-sandstorm.conf
  #
  #Disable default site:
  #  apache_site.enable:
  #    - name: 000-default.conf
