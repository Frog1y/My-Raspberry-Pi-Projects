# Media Server Installation & Setup Guide

Follow the steps to set up your very own automated Jellyfin + *arr stack media server.\
```NOTE:``` Some of these services frequently update their UI so some steps might be outdated. But the principles will remain the same so if you cannot find something mentioned in the steps below, Google it.

# docker-compose-yml
[docker-compose.yml]([https://github.com/Frog1y/My-Raspberry-Pi-Projects/blob/main/Media-Server/docker-compose.yml])

Take a look at this file and understand it. If you'll ever change storage, locations, networks etc. this is the file you'll be modifying.

All the containers are on the same network called ```medianet```. This is so the containers can communicate with eachother.

Look at all the ```volumes:``` under every service. The one that is the most important is ```./jellyfin:/data```. This means that the jellyfin directory inside your media-server is bound to the docker containers ```/data``` directory. Because of this every container has persistent data or "copy" of the ```~/media-server/jellyfin``` directory and all its contents. This also means that every time you update or restart the containers, that data will not change since it persists from your host.\
This essentially creates a ```/data``` directory inside every docker container that needs all the jellyfin directories to function properly.

Other volumes like ```./prowlarr:/config``` are config files, logs, caches etc. This is so that the settings you will be setting up in the GUI in the upcoming steps dont just reset even if you rebuild, remove or restart the containers.\
This essentially creates a directory inside your ```~/media-server``` host directory and binds it to the ```/config``` directory inside your docker containers.\
If you ever troubleshoot a container or service, this is also where you'll find the most common and useful logs.


# 1. Install Docker
Before doing anything you have to install Docker on your server.\
See documentation for your specific Linux distro & **Install Docker**:\
https://docs.docker.com/engine/install/

# 2. Create your folder structure.
If you only have one disk and this is your personal server I recommend you put the main media-server directory inside your users home directory: ```~/```.\
If you have a seperate disk mounted ment specifically for media you can create the main media-server directory inside that mount point. Example: ```/mnt/disk1```

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

4. Copy the ```docker-compose.yaml``` from [docker-compose.yml]([[https://link-url-here.org](https://github.com/Frog1y/My-Raspberry-Pi-Projects/blob/main/Media-Server/docker-compose.yml)]) and open the file you just created with any text editor like ```nano``` and paste.
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

2. Some new files will appear inside your ```~/media-server``` directory. Those are the persistent bind mounts from your containers we talked about in the ```docker-compose.yml``` section.

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
* **API Key**: Copy paste from Radarr web UI. Go to **Radarr web UI (http://YOUR_IP:7878)** -> **Settings** -> **General** -> **Security** -> **Copy API key**, and paste it.
* **Test** -> **Save**

**Settings** -> **Apps** -> **+** -> **Sonarr**:
* Prowlarr Server: http://prowlarr:9696
* Sonarr Server: http://sonarr:8989
* API Key: Copy paste from Sonarr web UI. Go to **Sonarr web UI (http://YOUR_IP:8989)** -> **Settings** -> **General** -> **Security** -> **Copy API key**, and paste it.
* **Test** -> **Save**

 Click **Sync App Indexers** (Top Menu button)

# 6. Configure Radarr - http://YOUR_IP:7878
**Settings** -> **Media Management**:
* Enable Rename Movies
* Add Root Folder: ```/data/media/Movies```

**Settings** -> **Download Clients** -> **+** -> **qBittorrent**:
* Host: qbittorrent
* Port: 8080
* Username(from qbittorrent): **admin** / Password(from qbittorrent): **<YOUR_PASSWORD>**
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

# 8. Configure Bazarr - http://YOUR_IP:6767
1. Add subtitle **Providers**
* **Settings** -> **Providers** -> **+**
* Recommended providers: **OpenSubtitles.com**, **OpenSubtitles.org**
* Create a free account on provider's site if you have to
* Enter your credentials from each provider
* **Save**

2. Set your **Languages**
* **Settings** -> **Languages** -> Select Languages from **Languages Filter**
* Optionally you can set a profile in the top right tab -> **Profiles**
* **Save**

3. Connect to **Sonarr**
* **Settings** -> **Libary** -> Open the **Sonarr tab** at the top side of the screen
* **Fill** in:
    * **Host**: sonarr
    * **Port**: 8989
    * **API Key**: Copy paste from Sonarr web UI. Go to **Sonarr web UI (http://YOUR_IP:8989)** -> **Settings** -> **General** -> **Security** -> **Copy API key**, and paste it.
    * **Test** -> **Save**

3. Connect to **Radarr**
* **Settings** -> **Libary** -> Open the **Radarr tab** at the top side of the screen
* **Fill** in:
    * **Host**: radarr
    * **Port**: 7878
    * **API Key**: Copy paste from Sonarr web UI. Go to **Radarr web UI (http://YOUR_IP:7878)** -> **Settings** -> **General** -> **Security** -> **Copy API key**, and paste it.
    * **Test** -> **Save**

# 9. Configure Jellyfin: http://YOUR_IP:8096
* Follow the setup wizard
* Add Library -> Movies -> folder:/data/media/Movies
* Add Library -> Shows -> folder:/data/media/tv
* From the top right menu -> **Dashboard** -> **API Keys** -> **+** -> **name it seerr** -> **copy the API key**

# 10. Configure Seerr: http://YOUR_IP:5055
* Select **Jellyfin** as media server
* **Fill** in:
    * **Host**: jellyfin
    * **Port**: 8096
    * **SSL**: Off
    * **URL** Base: Leave empty
* **Sign in** with jellyfin **admin** credentials
* Select **Movies and shows library** -> Continue (Or from **Dashboard** -> **Libraries**)
* Add **Radarr/Movies Library**:
    * **Hostname**: radarr / Port: 7878
    * **API Key**: Copy paste from Sonarr web UI. Go to **Radarr web UI (http://YOUR_IP:7878)** -> **Settings** -> **General** -> **Security** -> **Copy API key**, and paste it.
    * **Quality Profile**: HD-1080p
    * **Root Folder**: data/media/Movies
    * **Enable** -> **Test** -> **Save**
* Add **Sonarr/Shows Library**:
    * **Hostname**: sonarr / Port: 8989
    * **API Key**: Copy paste from Sonarr web UI. Go to **Sonarr web UI (http://YOUR_IP:8989)** -> **Settings** -> **General** -> **Security** -> **Copy API key**, and paste it.
    * **Quality Profile**: HD-1080p
    * **Root Folder**: data/media/tv
    * **Enable** -> **Test** -> **Save**
* **Finish**

# 11. Testing your configuration
* Open **Seerr (http://seerr:5055)** -> **Browse for any movie or show** -> **Click** on it -> Click **Request**
* Now, open **Radarr(http://YOUR_IP:7878)** -> **Movies** // or open **Sonarr (http://YOUR_IP:8989)** -> **Series**, **depending** on which content type you requested in **Seerr**.
* Make sure the content appears there. (Look at the **color code** there, which indicates your media state. Some movies or shows have not been released yet **marked blue for Unreleased**. Those will continue to be monitored until a sufficient match is found - at which point the media will auto download.)
* After your content appears from the previous step and is marked **Purple for queued** Open your **qBittorrent (http://YOUR_IP:8080)**. Your download should start downloading.
* After the download is complete the files will automatically be hardlinked from **~/media-server/jellyfin/media/downloads** to their respective **/tv** or **/Movies** directory.
* Your content will now appear in **Jellyfish** and you can watch. (Jellyfin scans the folders periodically so there might be a delay to when the files appear. You can immediately force them to appear by going to your **Dashboard** in the **Jellyfin web UI** -> Click **Scan All Libraries**)

# 12. Troubleshooting
* If your server gets stuck at any of the above steps, troubleshoot the specific service.
* Read container logs ```sudo docker logs <CONTAINER_NAME>```
* Read logs inside ```~/media-server/<CONTAINER_NAME>/logs``` or similar. Check the directories inside ur ```~/media-server```
* Check that your ```docker-compose.yml``` is set correctly. Specifically that your compose file volumes are readable by all containers that have them.
* Check for status errors on every service web UI (It will pop up as a notification in your side menu)
* Any issues you might have is most likely a ```docker-compose-yml``` being set up wrong or your configuration from above steps. Reference all of the above steps.
* Check for typos

# ADDITIONAL TIPS
* **Jellyfin App** is supported on almost all **smart TVs**. You can **download** it from Google/apple/play stores. After which all you have to do is **open it** -> provide your **servers IP and Port** -> **Log in**
* I recommend you set up a simple script and schedule it to run every now and then to update your system and docker containers. Or use watchtower.
* If you have enough storage you can create a script that auto requests media from Seerr and prunes that media from your machine on a schedule if you truly want a completely hands-off experience.
* Consider implementing a VPN to mask your downloading activies.
