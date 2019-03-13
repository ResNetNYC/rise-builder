# -*- coding: utf-8 -*-
# vim: ft=sls

base:
  '*':
    - salt
    - volumes
    - drbd
    - network
    - backups
    - pcs
    - sandstorm
    - unifi
