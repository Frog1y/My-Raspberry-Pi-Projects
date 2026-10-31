#!/bin/bash

# Watchdog script to remediate randomly lost ethernet connections. Logs steps since the system didn't log ethernet outage the last time.
# journalctl -t eth-watchdog
# journalctl -u eth-watchdog.service

# eth-watchdog: if the router stops answering on eth0, try soft resets and log what happened.
# Runs every 2 minutes from eth-watchdog.timer.
# Ran as a service /etc/systemd/system/eth-watchdog.service

FALLBACK_GW=192.168.64.1   # <-- set to your router's IP (used only if eth0 has no default route)

GW=$(ip route show default dev eth0 2>/dev/null | awk '{print $3; exit}')
GW=${GW:-$FALLBACK_GW}

log()   { logger -t eth-watchdog "$*"; }
check() { ping -c 3 -W 2 -I eth0 "$GW" >/dev/null 2>&1; }

check && exit 0

CARRIER=$(cat /sys/class/net/eth0/carrier 2>/dev/null || echo unknown)
log "gateway $GW unreachable (carrier=$CARRIER), trying renegotiate"
ethtool -r eth0; sleep 15
check && { log "recovered via renegotiate"; exit 0; }

log "trying link down/up"
ip link set eth0 down; sleep 2; ip link set eth0 up; sleep 20
check && { log "recovered via link bounce"; exit 0; }

log "still dead after soft fixes, power cycle needed"
exit 1