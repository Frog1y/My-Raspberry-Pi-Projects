# Samba SMB
Packages: samba, samba-common-bin\
Shared folder in user's home directory /home/raspi/samba-share\
Samba user: raspi\
Samba config /etc/samba/smb.conf:
```yaml
[raspi-share]
path = /home/raspi/samba-share
writeable = yes
browseable = yes
public = no
