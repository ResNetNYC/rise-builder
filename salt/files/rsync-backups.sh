#!/bin/bash

# Sync backups from primary server
/usr/bin/rsync -Huaz --delete --exclude lost+found rsync://10.1.0.10/backups /mnt/backups/

# Restore Sandstorm
cd /opt/sandstorm
rsync -uav /mnt/backups/hourly.0/localhost/opt/sandstorm/* .

# Restore UNMS
cd /home/unms
rsync -uav /mnt/backups/hourly.0/localhost/home/unms/* .

# Restore Unifi
cd /var/lib/unifi
rsync -uav /mnt/backups/hourly.0/localhost/var/lib/unifi/* .
