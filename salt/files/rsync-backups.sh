#!/bin/bash

/usr/bin/rsync -Huaz --delete --exclude lost+found rsync://10.1.0.10/backups /mnt/backups/

