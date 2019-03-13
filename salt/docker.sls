# -*- coding: utf-8 -*-
# vim: ft=sls

Install Docker repo dependencies:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - ca-certificates
      - curl

Setup Docker apt repository:
  pkgrepo.managed:
    - name: deb https://download.docker.com/linux/debian stretch stable
    - file: /etc/apt/sources.list.d/docker.list
    - require:
      - pkg: Install Docker repo dependencies
    - key_url: https://download.docker.com/linux/debian/gpg

Install Docker and bindings:
  pkg.installed:
    - pkgs:
      - docker-ce
      - python-docker
    - require:
      - pkgrepo: Setup Docker apt repository
    - reload_modules: True

Run Docker:
  service.running:
    - name: docker
    - require:
      - pkg: Install Docker and bindings
