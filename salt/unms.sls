# -*- coding: utf-8 -*-
# vim: ft=sls

Install Apache:
  pkg.installed:
    - name: apache2

Install UNMS:
  cmd.script:
    - name: cmd --http-port 9000 --https-port 9443 --unattended
    - source: https://raw.githubusercontent.com/Ubiquiti-App/UNMS/master/install.sh
    - runas: root

#UNMS Apache config:
#  apache.configfile:
#    - name: /etc/apache2/sites-available/unms.conf
#    - config:
#      - Virtualhost:
#          this: '*:80'
#          ServerName:
#            - unms.{# grains['domain'] }}
#          Location:
#            this: '/'
#            ProxyPreserveHost: On
#            ProxyPass: http://{{ grains['fqdn'] }}:9000
#            ProxyPassReverse: http://{{ grains['fqdn'] #}:9000
#
#Enable UNMS site:
#  apache_site.enable:
#    - name: unms.conf
