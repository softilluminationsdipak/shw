#!/bin/sh
rm tmp/always_restart.txt && touch tmp/restart.txt && rsync -a --delete . root@staging.selecthomewarranty.com:/var/www/eripme/current && touch tmp/always_restart.txt