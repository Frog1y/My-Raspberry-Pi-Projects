#!/bin/bash
# =============================================================================
# eth-watchdog: Ethernet watchdog for the Raspberry Pi 5
# =============================================================================
# DIR: /usr/local/bin/eth-watchdog.sh
# SERVICE: /etc/systemd/system/eth-watchdog.service
#
# WHY THIS EXISTS
# ---------------
# The Pi's onboard Ethernet (RP1 chip, "macb" driver) occasionally stops
# passing traffic while everything else on the network keeps working.
# Seen on Oct 28 and Oct 31 2026, roughly every 3-4 days of uptime.
#
# What we know about the failure:
#   - The physical link stays UP (1Gbps/Full) and the kernel logs no errors,
#     so nothing on the system notices; traffic just silently stops.
#   - Not caused by power (vcgencmd get_throttled = 0x0) or by EEE
#     (Energy Efficient Ethernet is disabled).
#   - Unplugging and replugging the cable did NOT fix it.
#   - Only a full power cycle has fixed it so far; a reboot alone has never
#     helped, so this script deliberately never reboots.
#
# WHAT IT DOES
# ------------
# Run every 2 minutes by eth-watchdog.timer. Pings the router through eth0.
# If the router doesn't answer, it tries progressively stronger soft fixes:
#   1. ethtool -r       (renegotiate the link with the switch)
#   2. link down/up     (driver tears down and restarts the interface)
# and logs the result, including the carrier state at the time of failure.
#
# The goal is both to recover automatically where possible AND to find out
# which layer is failing, so the root cause can be narrowed down:
#   "recovered via renegotiate" -> link/negotiation-level problem
#   "recovered via link bounce" -> driver/interface getting stuck
#   "power cycle needed"        -> chip is wedged; only cutting power helps
#                                  
#
# Check the history with:  journalctl -t eth-watchdog
# =============================================================================

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