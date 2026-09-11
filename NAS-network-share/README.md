# Samba Server - Network Shared Storage.

## Shared folder in user's home directory /home/raspi/samba-share
## Samba user: raspi
## Mapped share address: \\192.168.64.200\raspi-share
## Samba config /etc/samba/smb.conf:
```yaml
[raspi-share]
path = /home/raspi/samba-share
writeable = yes
browseable = yes
public = no
