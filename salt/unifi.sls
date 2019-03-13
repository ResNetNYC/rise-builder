# -*- coding: utf-8 -*-
# vim: ft=sls

ubiquiti_apt_packages:
  pkg.installed:
    - pkgs:
      - python-apt
      - aptitude
      - debconf-utils
      - apt-utils
      - apt-transport-https

ubiquiti_repo:
  pkgrepo.managed:
    - humanname: Ubiquiti repo
    - name: deb http://www.ui.com/downloads/unifi/debian stable ubiquiti
    - file: /etc/apt/sources.list.d/ubiquiti.list
    - gpgcheck: 1
    - key_url: https://dl.ui.com/unifi/unifi-repo.gpg
    - require:
      - pkg: ubiquiti_apt_packages
    - require_in:
      - pkg: ubiquiti_pkg

ubiquiti_pkg:
  pkg.latest:
    - name: unifi
    - refresh: True
