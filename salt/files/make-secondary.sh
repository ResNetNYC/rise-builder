#!/bin/bash

systemctl stop docker sandstorm unifi rsync rsnapshot-nightly.timer
systemctl disable docker sandstorm unifi rsync rsnapshot-nightly.timer
systemctl enable rsync-backups.timer
systemctl start rsync-backups.timer

cp /usr/local/share/dnsmasq.conf.secondary /etc/dnsmasq.conf
systemctl restart dnsmasq
