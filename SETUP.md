# IMAGING
Raspberry Pi imager\
Ubuntu Server\

## Booting DHCP - Network Issue
​A network switch is like a power strip—it adds more plugs, but it doesn't generate "power" (IP addresses) on its own. Your router is the only device that runs a service called DHCP (Dynamic Host Configuration Protocol), which hands out IP addresses to devices so they can talk to the internet.\
​When I booted the Pi, it asked the switch for an IP address. The switch tried to forward that request to my router. If the connection between the switch and the router was asleep, dropped, or jammed with stale data, the router never heard the Pi's request.\

### eth0 in limbo - Connected physically, but ignored by the OS.
On boot Cloud-Init did not get an ip address on the network switch.\
Even though the internet connection was established - both ethernet ports receiving data and connected.\
Could establish that the connection is active but IP is not resolved by running the command "ip a". The eth0 was UP but without an IPv4 address.

### FIX:
### sudo systemctl restart systemd-networkd
restarted Pi's OS networking.
### sudo networkctl renew eth0
resolved addressing and connection by requesting for IP address.
