#!/bin/bash

systemctl stop docker
systemctl disable docker
systemctl stop containerd
systemctl disable containerd
systemctl stop sandstorm
systemctl disable sandstorm
systemctl stop unifi
systemctl disable unifi
systemctl stop rsync
systemctl disable rsync
systemctl stop rsnapshot-nightly.timer
systemctl disable rsnapshot-nightly.timer
systemctl start rsync-backups.timer
systemctl enable rsync-backups.timer

cp /usr/local/share/dnsmasq.conf.primary /etc/dnsmasq.conf
systemctl restart dnsmasq
