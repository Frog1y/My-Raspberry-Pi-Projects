#!/bin/bash
# Shut down the Raspberry Pi cleanly when mains power is lost (Geekworm X1201).
# Fail-safe: only counts as power lost when GPIO6 clearly reads "lo".

PIN=6        # X1201 power-loss detection pin
DELAY=300    # seconds the power must stay off continuously before shutting down

pinctrl set $PIN ip pn

# Succeeds only if pinctrl runs AND clearly reports "lo" (power lost).
power_lost() {
    pinctrl get $PIN 2>/dev/null | grep -q "| lo"
}

seconds_off=0    # how many seconds in a row the power has been off

while true; do
    if power_lost; then
        if [ $seconds_off -eq 0 ]; then
            echo "Mains power lost. Shutting down in $DELAY seconds unless it returns."
        fi
        seconds_off=$((seconds_off + 1))
        if [ $seconds_off -ge $DELAY ]; then
            echo "Power off for $DELAY seconds, shutting down."
            systemctl poweroff
            exit 0
        fi
    else
        if [ $seconds_off -gt 0 ]; then
            echo "Mains power restored after $seconds_off seconds, shutdown cancelled."
        fi
        seconds_off=0
    fi
    sleep 1
done