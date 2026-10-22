### Update your host machine
```shell
sudo apt update && sudo apt upgrade
```

---

### Update, recreate and prune Docker containers and images.
```shell
sudo docker compose pull
sudo docker compose up --force-recreate --build -d
sudo docker image prune -f
```