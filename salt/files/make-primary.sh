#!/bin/bash

systemctl enable docker sandstorm unifi rsync rsnapshot-nightly.timer
systemctl start docker sandstorm unifi rsync rsnapshot-nightly.timer
systemctl disable rsync-backups.timer
systemctl stop rsync-backups.timer

cp /usr/local/share/dnsmasq.conf.primary /etc/dnsmasq.conf
systemctl restart dnsmasq
