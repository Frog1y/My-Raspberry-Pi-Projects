# Beszel - Simple, lightweight server monitoring

<img width="408" height="166" alt="image" src="https://github.com/user-attachments/assets/49b5a24b-2c37-4bda-9aed-97e573f4a6a8" />


Beszel is a lightweight server monitoring tool.\
The setup requires a Beszel monitoring server + an agent on any of your machines you want to monitor.\
You can run both in docker containers using docker compose.

Server docker compose: [docker-compose-server.yml](https://github.com/Frog1y/My-Raspberry-Pi-Projects/blob/main/Beszel-system-monitoring/docker-compose-server.yml)\
Agent docker compose: [docker-compose-agent.yml](https://github.com/Frog1y/My-Raspberry-Pi-Projects/blob/main/Beszel-system-monitoring/docker-compose-agent.yml)

## Administration
Web Console: ```http://<YOUR_IP>:8090```

## Setup

Follow Beszel official documentation:\
https://beszel.dev/guide/getting-started

## Alerts & Notifications
Select your notification media.
Follow Beszel official documentation:\
https://beszel.dev/guide/notifications/

I created a Discord web hook.\
You can configure notifications and alerts by clicking on the bell icon on any selected System.
