#!/bin/bash

# Watchdog script to remediate randomly lost ethernet connections. Logs steps since the system didn't log ethernet outage the last time.
# journalctl -t eth-watchdog
# journalctl -u eth-watchdog.service

# Service;
# /etc/systemd/system/eth-watchdog.service
# /etc/systemd/system/eth-watchdog.timer


# Checks if the router is reachable via eth0; if not, tries progressively stronger fixes.

GW=$(ip route | awk '/default.*eth0/ {print $3; exit}')
[ -z "$GW" ] && GW=192.168.1.1   # fallback: set your router IP

# Don't reboot within 30 min of boot (prevents reboot loops if the router is down)
[ "$(cut -d. -f1 /proc/uptime)" -lt 1800 ] && NOREBOOT=1

check() { ping -c 3 -W 2 -I eth0 "$GW" >/dev/null; }

check && exit 0

logger -t eth-watchdog "gateway $GW unreachable, trying ethtool -r"
ethtool -r eth0; sleep 15
check && { logger -t eth-watchdog "recovered via renegotiate"; exit 0; }

logger -t eth-watchdog "trying link down/up"
ip link set eth0 down; sleep 2; ip link set eth0 up; sleep 20
check && { logger -t eth-watchdog "recovered via link bounce"; exit 0; }

if [ -z "$NOREBOOT" ]; then
    logger -t eth-watchdog "still dead, rebooting"
    systemctl reboot
else
    logger -t eth-watchdog "still dead, but uptime < 30 min, skipping reboot"
fi