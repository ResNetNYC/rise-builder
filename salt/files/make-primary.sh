#!/bin/bash

systemctl enable docker
systemctl start docker
systemctl enable containerd
systemctl start containerd
systemctl enable sandstorm
systemctl start sandstorm
systemctl enable unifi
systemctl start unifi
systemctl disable rsync-backups.timer
systemctl stop rsync-backups.timer

cp /usr/local/share/dnsmasq.conf.secondary /etc/dnsmasq.conf
systemctl restart dnsmasq
