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

## Setting up SSH Auth keys.
In the imaging proccess I already predefined SSH installation before booting and installing the Ubuntu Server OS.
### ssh-keygen
generated ssh key in the windows powershell terminal.
### type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh raspi@raspberry-pi-5 "cat >> ~/.ssh/authorized_keys"
Copied the public key:\
"$env:USERPROFILE\.ssh\id_ed25519.pub"\
Piped to ssh into my Pi and append the public key into the authorized_keys file:\
ssh raspi@raspberry-pi-5 "cat >> ~/.ssh/authorized_keys"

## Configuring a static IP address on my Pi - Without router setting.
I can not access my router setting on my LAN.\
On Ubuntu Server, network configuration is managed via Netplan.\
First I had to find the Netplan config file:\
### ls /etc/netplan/
resulted in "50-cloud-init.yaml" config file
### sudo nano /etc/netplan/50-cloud-init.yaml
Updated the yaml config file to the following:\
"""\
  network:\
  version: 2\
  renderer: networkd\
  ethernets:\
    eth0: # My interface / Ethernet connection\
      dhcp4: no\
      addresses:\
        - 192.168.x.200/24 # My desired static IP and subnet\
      routes:\
        - to: default\
          via: 192.168.x.1 # My gateway/router IP\
      nameservers:\
        addresses: [8.8.8.8, 1.1.1.1] # Your DNS server\
"""
### ip a
Pi is now reachable on my LAN IPv4 address: x.x.x.200