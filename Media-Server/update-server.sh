# This script updates your packages & pulls media-server docker container images and recreates them. Deletes or prunes older images.
# It logs the output to a directory ~/media-server/update-logs/

LOGFILE="update-log_$(date +%Y-%m-%d_%H:%M).log"

exec > >(tee -a ~/media-server/update-logs/"$LOGFILE") 2>&1

sudo apt update && sudo apt upgrade -y
sudo docker compose pull
sudo docker compose up --force-recreate --build -d
sudo docker image prune -f