# Media Server Installation & Setup Guide

# docker-compose-yml
```docker-compose.yml```

Take a look at this file and understand it. If you'll ever change storage, locations, networks etc. this is the file you'll be modifying.

All the containers are on the same network called ```medianet```. This is so the containers can communicate with eachother.

Look at all the ```volumes:``` under every service. The one that is the most important is ```./jellyfin:/data```. This means that the jellyfin directory inside your media-server is bound to the docker containers data directory. Because of this every container has persistent data of the ```~/media-server/jellyfin``` directory and all its data.\
This essentially creates a ```/data``` directory inside every docker container that requires jellyfin media data.

Other volumes like ```./prowlarr:/config``` are config files, logs, caches etc. This is so that the settings you will be setting up in the GUI in the upcoming steps remain persistent even if you rebuild, remove or restart the containers.\
This essentially creates a directory inside your ```~/media-server``` directory and binds it to the ```/config``` directory inside your docker containers.\
If you ever troubleshoot a container or service, this is also where you'll find the most common and useful logs.

# 1. Install Docker
See documentation for your specific Linux distro:\
https://docs.docker.com/engine/install/

# 2. Create your folder structure.
If you only have one disk and this is your personal server I recommend you put the main directory inside your users home directory: ```~/```.\
If you have a seperate disk mounted ment specifically for media you can create the man directory inside the mount point. Example: ```/mnt/disk1```

## Folder Structure:
1. This is what you will be making:
```
├── docker-compose.yml
└──── jellyfin/
      └── media/
          ├── Movies/             
          ├── tv/                 
          └── downloads/          
```

2. Create your directories:
```
mkdir -p ~/media-server
mkdir -p ~/media-server/jellyfin/media/Movies
mkdir -p ~/media-server/jellyfin/media/tv
mkdir -p ~/media-server/jellyfin/media/downloads
```

3. Create the docker-compose file in the main server directory.
```
touch ~/media-server/docker-compose.yaml
```

4. Copy the ```docker-compose.yaml``` from LINK and open the file you just created with any text editor like ```nano``` and paste.
```
nano ~/media-server/docker-compose.yaml
-> PASTE
```

# 3. Run docker containers and set permissions.

1. Run your docker containers from the compose file.
```
cd ~/media-server
sudo docker compose up -d
```

2. Some new files will appear inside your ```~/media-server``` directory. Those are the persistent bind mounts from your containers we talker about in the ```docker-compose.yml``` section.

3. Set initial permissions for Seerr and restart said container.
```
sudo chown -R 1000:1000 ~/media-stack/seerr
sudo chmod -R 755 ~/media-stack/seerr
docker restart seerr
```

# 4. Configure qBittorrent - http://YOUR_IP:8080
1. Find and copy your temporary password. 
```
docker logs qbittorrent | grep password
```
2. Log in with the username ```admin``` and the password you copied earlier.

3. Change your password in the GUI ```http://YOUR_IP:8080```\
    -> **Tools** -> **Options** -> **WebUI** -> Set new password

4. Configure the default save path\
    -> **Tools** -> **Options** -> **Downloads** -> Set **Default Save Path** to ```/data/media/downloads```    *~ This is the persistent volume bind inside the docker container*

# 5. Configure Prowlarr - http://YOUR_IP:9696

1. Add FlareSolverr Proxy\
    -> **Settings** -> **Indexers** -> Click **+**

2. Select FlareSolverr and fill in:
* name:  ```FlareSolverr```
* host:  ```http://flaresolverr:8191```
* tag:  ```flaresolverr```

3. Click **test** -> **save**
---

4. Add Indexers\
    -> **Indexers** -> click **Add Indexer**\


**For Each:**

| Service | Best For | FlareSolverr Tag Needed |
| :--- | :--- | :--- |
| **YTS** | Movies (small size) | No |
| **EZTV** | TV Shows | No
| **1337x** | 	Movies & TV | Yes
| **The Pirate Bay** | General | Yes

Search by **name** -> select **Base URL** -> add **flaresolverr tag** if needed -> **Test** -> **Save**\
```NOTE:``` Feel free to use your own indexers. These are the torrent sites that provide you with your download.

---

5. Link to Radarr & Sonarr

**Settings** -> **Apps** -> **+** -> **Radarr**:
* **Prowlarr Server**: http://prowlarr:9696
* **Radarr Server**: http://radarr:7878
* **API Key**: Copy paste from Radarr web UI. Go to **Radarr web UI (http://radarr:7878)** -> **Settings** -> **General** -> **Security** -> **Copy API key**, and paste it.
* **Test** -> **Save**

**Settings** -> **Apps** -> **+** -> **Sonarr**:
* Prowlarr Server: http://prowlarr:9696
* Sonarr Server: http://sonarr:8989
* API Key: Copy paste from Radarr web UI. Go to **Radarr web UI (http://sonarr:8989)** -> **Settings** -> **General** -> **Security** -> **Copy API key**, and paste it.
* **Test** -> **Save**
* Click **Sync App Indexers**

# 6. Configure Radarr - http://YOUR_IP:7878
**Settings** -> **Media Management**:
* Enable Rename Movies
* Add Root Folder: ```/data/media/Movies```

**Settings** -> **Download Clients** -> **+** -> **qBittorrent**:
* Host: qbittorrent
* Port: 8080
* Username: admin / Password: your password
* Test -> Save

**Settings** -> **Indexers** - verify indexers are listed

# 7. Configure Sonarr — http://YOUR_IP:8989
**Settings** -> **Media Management**:
* Enable Rename Episodes
* Add Root Folder: ```/data/media/tv```

**Settings** -> **Download Clients** -> **+** -> **qBittorrent**:
* Host: qbittorrent
* Port: 8080
* Username: admin / Password: your password
* Test -> Save

**Settings** -> **Indexers** - verify indexers are listed