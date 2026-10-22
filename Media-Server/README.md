# Media Server 

Fully automated LAN media server. Running in a fleet of docker containers.\
You request practically any movie or show -> the server requests, finds, downloads and serves content.

# Setup
If you are interested in installing and configuring this stack yourself, feel free to use my documentation:

LINK

🔗 ```My Specs```

```⚠ NOTE: ⚠``` Every note, step, structure, documentation is based on my own setup which is Linux Ubuntu 26.04 LTS.\
You can run this stack in a Windows enviornment aswell but this documentation only covers setup in Linux.

## Services/Docker containers:
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
[docker-compose.yml]()


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

## Media Server folder structure
```
~/media-server/ 
├── docker-compose.yml
├── update-media-stack.sh    <- pulls latest images & restarts the stack
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
You can use ~/ as your starting path. This is your users home directory. Or you can create this structure anywhere you wish.\


## Usage

You navigate into your server folder. In my case its ~/media-server.\
You issue a docker command ```sudo docker compose up -d```\
Your docker containers, and the full app stack is now running\
After everything is configured (see:LINK)\
You can now use the full stack from their respective web UIs.\
You can update the stack from: LINK (I recommend you run this on schedule)
