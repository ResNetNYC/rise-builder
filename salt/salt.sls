# -*- coding: utf-8 -*-
# vim: ft=sls

apt_packages:
  pkg.installed:
    - pkgs:
      - python-apt
      - aptitude
      - debconf-utils
      - apt-utils
      - apt-transport-https

salt_repo:
  pkgrepo.managed:
    - humanname: Saltstack repo
    - name: deb http://repo.saltstack.com/apt/debian/{{ grains['osmajorrelease'] }}/amd64/2018.3 stretch main
    - file: /etc/apt/sources.list.d/salt.list
    - gpgcheck: 1
    - key_url: https://repo.saltstack.com/apt/debian/{{ grains['osmajorrelease'] }}/amd64/2018.3/SALTSTACK-GPG-KEY.pub
    - require:
      - pkg: apt_packages
    - require_in:
      - pkg: salt_pkg

salt_pkg:
  pkg.latest:
    - name: salt-minion
    - refresh: True

