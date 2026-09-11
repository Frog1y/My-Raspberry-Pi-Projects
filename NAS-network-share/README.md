# Samba Server - Network Shared Storage.
<img width="280" height="90" alt="image" src="https://github.com/user-attachments/assets/7ebc994e-fa56-4b4b-8924-e3d4142889aa" />

Shared folder in user's home directory /home/raspi/samba-share\
Samba user: raspi\
Mapped share address:\\192.168.64.200\raspi-share\
Samba config /etc/samba/smb.conf:
```yaml
[raspi-share]
path = /home/raspi/samba-share
writeable = yes
browseable = yes
public = no
