# Media Server 

Fully automated LAN media server using Jellyfin and the *arr stack. Running in a fleet of docker containers.\
You request movie or show -> the server requests, finds, downloads and serves your content in Jellyfin (Netflix style UI).

# Setup
If you are interested in installing and configuring this stack yourself, feel free to use my documentation:

LINK

🔗 ```My Specs```

```Prerequisites:``` A linux server/VM.\
```Recommended specs:``` 4GB+ RAM. 50GB+ Storage. The more the merrier.\

## Services/Docker Containers:
```Jellyfin```
A free, open-source media server that streams your movies, TV shows, and music to your devices with a Netflix-style interface.\
```Seerr```
A media request and discovery management tool that lets users request movies and TV shows via a web UI.\
```Prowlarr```
An indexer manager that connects your torrent and Usenet indexers to your automated downloaders (Radarr, Sonarr, etc.).\
```Radarr```
An automated movie downloader and library manager that tracks upcoming releases and triggers downloads.\
```Sonarr```
An automated TV show downloader and library manager that monitors episode releases and keeps series up to date.\
```Bazarr```
An automated subtitle downloader that fetches missing subtitles for media files in your Radarr and Sonarr libraries.\
```qBittorrent```
A BitTorrent client that handles the actual downloading of media files to your storage.\
```Flaresolverr```
A proxy server that bypasses Cloudflare DDoS protection on indexer websites so tools like Prowlarr can access them.

## How the stack works:
```[ Seerr ] ➔ [ Radarr / Sonarr ] ➔ [ Prowlarr ] ➔ [ qBittorrent ] ➔ [ Bazarr ] ➔ [ Jellyfin ]```

 * You request your media in the Seerr UI.
 * Radarr/Sonarr immediately picks up the request and start monitoring the media.
 * Prowlarr starts searching for a torrent from your configured indexers.
 * qBittorrent client downloads the torrent.
 * Radarr/Sonarr renames and moves the files to your Jellyfin folders.
 * Bazarr downloads the the subtitles for the new file.
 * Jellyfin detects the new file and it now appears in your jellyfin library.
 * You can now watch your movies and shows on your LAN on any device that is compatible with the jellyfin app (most smart tvs, pcs, phones etc.)

 ```NOTE``` Flaresolverr is just a bypass mechanism for configured indexers in Prowlarr that require Cloudflare anti-bot/DDoS protection.

 
## Docker Compose 🐳
[docker-compose.yml](https://github.com/Frog1y/My-Raspberry-Pi-Projects/blob/main/Media-Server/docker-compose.yml)


## Services/Docker containers Web GUI cheatsheet:
Services are mostly configured, managed and/or used through their web consoles.\
The table below highlights every service's respective address and port.

| Service | Purpose | Port | Web UI |
| :--- | :--- | :--- | :--- |
| **Jellyfin** | Stream movies & TV shows | `8096` | `http://YOUR_IP:8096` |
| **Seerr** | Request movies & TV shows | `5055` | `http://YOUR_IP:5055` |
| **Radarr** | Auto manage & download movies | `7878` | `http://YOUR_IP:7878` |
| **Sonarr** | Auto manage & download TV shows | `8989` | `http://YOUR_IP:8989` |
| **Prowlarr** | Search torrent indexers | `9696` | `http://YOUR_IP:9696` |
| **qBittorrent** | Downloads torrents | `8080` | `http://YOUR_IP:8080` |
| **Bazarr** | Downloads subtitles | `6767` | `http://YOUR_IP:6767` |
| **FlareSolverr** | Bypass Cloudflare on indexers | `8191` | `/` |

## Media Server Folder Structure
```
~/media-server/ 
├── docker-compose.yml
├── update-server.sh     <- Script for updating your server packages, and your media-server stack.
│
├── update-logs/         <- Your update-server.sh logs
│
├── jellyfin/
│   ├── config/          <- Jellyfin config, users, watch history
│   ├── cache/           <- Jellyfin cache
│   └── media/
│        ├── Movies/             <- Final movie files with subtitles (hardlinks)
│        ├── tv/                 <- Final TV show files with subtitles (hardlinks)
│        └── downloads/          <- Downloads folder, files download here.
│
├── prowlarr/            <- Prowlarr config/logs
├── radarr/              <- Radarr config/logs
├── sonarr/              <- Sonarr config/logs
├── qbittorrent/         <- qBittorrent config/logs
├── bazarr/              <- Bazarr config/logs
├── seerr/               <- Seerr config/logs
└── flaresolverr/        <- FlareSolverr config/logs
```


## Usage

* You browse and request any movie or tv show on **Seerr** ```http://YOUR_IP:5055```.
* The media will be monitored and downloaded in the background.
* Once that process completes you can watch your media in **Jellyfin** ```http://YOUR_IP:8096```.

If you wish to delete media to free up space on your storage devices, the best way to do so is from the Sonarr/Radarr web UIs: ```http://YOUR_IP:8989``` ```http://YOUR_IP:7878```.\
Update your stack every now and then or use a script to update it automatically on a schedule.\
You can download the Jellyfin App on most smart TVs. Or just watch it from any browser on your PC.
