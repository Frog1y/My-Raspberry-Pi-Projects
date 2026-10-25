# Raspberry Pi 5 + Geekworm X1201 UPS: Safe Shutdown on Power Loss

A minimal setup that shuts a Raspberry Pi 5 down cleanly when mains power is lost, using the Geekworm X1201 UPS HAT. The Pi powers off completely afterwards and boots again automatically when power returns.

## Setup

| Component | Details |
|---|---|
| Board | Raspberry Pi 5 |
| UPS | Geekworm X1201 (2× 18650 cells) |
| OS | Ubuntu 26.04 LTS (kernel `7.0.0-raspi`) |
| Power | 5V 5A adapter plugged into the **X1201's** USB-C port (not the Pi's) |

## How it works

The X1201 reports mains power status on **GPIO6**:

| GPIO6 level | Meaning |
|---|---|
| `hi` | Adapter is supplying power |
| `lo` | Mains power lost, running on batteries |

A small bash script reads GPIO6 once per second using `pinctrl`. If the power stays off **continuously** for `DELAY` seconds, it runs a clean `systemctl poweroff`. If the power returns before that, the countdown resets.

The full cycle:

```
power cut → wait DELAY → clean shutdown → Pi fully off → UPS cuts output
         → power returns → UPS auto power-on → Pi boots → script starts again
```

## Files

| File | Purpose |
|---|---|
| `/usr/local/bin/ups-shutdown.sh` | The shutdown script |
| `/etc/systemd/system/ups-shutdown.service` | Runs the script at every boot |
| Bootloader EEPROM | `POWER_OFF_ON_HALT=1` (and optionally `PSU_MAX_CURRENT=5000`) |
| `/boot/firmware/config.txt` | `usb_max_current_enable=1` (set earlier, when the UPS was first installed) |

## Installation

### 1. Check the hardware signal

```bash
sudo pinctrl set 6 ip pn     # set GPIO6 as input, no pull resistor
sudo pinctrl get 6           # should show "| hi" with the adapter plugged in
sudo watch -n1 pinctrl get 6 # unplug the adapter: should switch to "| lo"
```

### 2. Create the script

```bash
sudo tee /usr/local/bin/ups-shutdown.sh > /dev/null << 'EOF'
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
EOF
sudo chmod +x /usr/local/bin/ups-shutdown.sh
```

### 3. Create the systemd service

```bash
sudo tee /etc/systemd/system/ups-shutdown.service > /dev/null << 'EOF'
[Unit]
Description=Geekworm X1201 UPS safe shutdown monitor
After=multi-user.target

[Service]
ExecStart=/usr/local/bin/ups-shutdown.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ups-shutdown.service
```

### 4. Set the bootloader so the Pi powers fully off

```bash
sudo apt install -y rpi-eeprom
sudo rpi-eeprom-config --edit
```

Add:

```
POWER_OFF_ON_HALT=1
```

Then `sudo reboot`.

**Why this matters:** by default, a Pi 5 that has shut down stays in standby (red LED) and keeps drawing power, so the UPS never switches off, the batteries drain, and the Pi does **not** boot again when power returns. With `POWER_OFF_ON_HALT=1`, the Pi powers fully off, the X1201 cuts its output, and its auto power-on restarts the Pi when mains power comes back.

## Configuration notes

### DELAY

`DELAY` is the only thing deciding when to shut down. There is **no battery-level check**, so keep it well within the battery runtime.

Rough runtime with 2× ~3000 mAh cells (about 14–17 Wh usable):

| Pi load | Power | Approx. runtime |
|---|---|---|
| Idle / light | 3–4 W | 4–5 h |
| Moderate | 4–6 W | 2.5–3.5 h |
| Heavy / NVMe / USB devices | 7–10 W+ | 1.5–2 h |

Rule of thumb: set `DELAY` to at most **¼–⅓ of the estimated runtime**, to allow for battery ageing and back-to-back outages. **900 s (15 min)** is a good default.

To change it, edit `DELAY=` in the script, then run `sudo systemctl restart ups-shutdown.service`.

### Power settings: two separate places

| Location | Setting | Purpose |
|---|---|---|
| `/boot/firmware/config.txt` | `usb_max_current_enable=1` | Allow full USB current regardless of the detected PSU |
| Bootloader EEPROM | `PSU_MAX_CURRENT=5000` (optional) | Tell the Pi it has a 5 A supply; the same effect for USB current |
| Bootloader EEPROM | `POWER_OFF_ON_HALT=1` (**required**) | Full power-off on shutdown; only exists in the EEPROM |

The two current settings don't conflict; only one is needed.

## Everyday commands

| Task | Command |
|---|---|
| Service status | `systemctl status ups-shutdown.service` |
| Live log | `journalctl -u ups-shutdown.service -f` |
| Restart after editing the script | `sudo systemctl restart ups-shutdown.service` |
| Stop temporarily (e.g. to run on battery on purpose) | `sudo systemctl stop ups-shutdown.service` |
| Start again | `sudo systemctl start ups-shutdown.service` |
| Disable completely | `sudo systemctl disable --now ups-shutdown.service` |
| Read GPIO6 manually | `sudo pinctrl get 6` |
| View bootloader settings | `sudo rpi-eeprom-config` |

## Testing

1. Temporarily set `DELAY=10` and restart the service.
2. Watch the log: `journalctl -u ups-shutdown.service -f`
3. Unplug for a few seconds, then replug. Expected: "restored, shutdown cancelled".
4. Unplug and leave it out. Expected: shutdown after 10 s, and all LEDs go dark.
5. Replug. Expected: the Pi boots by itself.
6. Set `DELAY` back to its normal value.

Edge case worth testing once: replug **during** the shutdown. The Pi may stay off until the adapter is unplugged and replugged.

## LEDs

| LED | Meaning |
|---|---|
| Pi LED red | Pi halted / standby (should no longer persist after shutdown with `POWER_OFF_ON_HALT=1`) |
| Pi LED green | Pi running |
| X1201 D1–D4 | Battery level: 4 on = 100% (3.87–4.2 V), 3 = 75%, 2 = 50%, 1 = 25%, none = below 3.4 V |
| One level LED slowly blinking | Most likely charging (not documented by Geekworm) |

## Troubleshooting: what went wrong during setup

| Problem | Cause | Fix |
|---|---|---|
| `pinctrl get 6` showed `no pu \| --` | GPIO6 was not configured as an input | `sudo pinctrl set 6 ip pn` (the script does this itself) |
| Python/gpiozero: `can not open gpiochip` / `BadPinFactory` | The lgpio library can't open the GPIO chip on Ubuntu 26.04 / kernel 7.0 (even with `chip=0`) | Dropped Python and used `pinctrl` in a bash script instead |
| `Permission denied` when running the script | File was not executable | `sudo chmod +x /usr/local/bin/ups-shutdown.sh` |
| Pi LED stayed red after shutdown; UPS stayed on; no auto-boot | Pi 5's default halt state keeps drawing power | `POWER_OFF_ON_HALT=1` in the EEPROM |

## Known limitations

- **No battery monitoring:** relies on `DELAY` being safely short. Old cells can fail early, so replace them if the level LEDs drop quickly during outages.
- **Depends on `pinctrl`:** the script is fail-safe. If `pinctrl` disappears or its output format changes, the script never shuts down (rather than shutting down in a loop). Re-test after major OS upgrades.
- **Running on battery on purpose** will trigger a shutdown, so stop the service first.

## References

- [Geekworm X1201 wiki](https://wiki.geekworm.com/X1201)
- [X1201 hardware (GPIO pins, LED table)](https://wiki.geekworm.com/X1201_Hardware)
- [Official Geekworm/SupTronics scripts (Python, Raspberry Pi OS)](https://github.com/suptronics/x120x)
