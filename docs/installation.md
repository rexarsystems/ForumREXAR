# Installing and updating ForumREXAR

## Requirements

- A Linux server with **Ubuntu** or **Debian** (amd64 or arm64). Amazon Linux is not supported by the installer.
- Root (sudo) access.
- A domain is optional; without one the forum runs on the server's IP address.

## One-line installer

```bash
curl -sSL https://forum.rexar.net/cdn/2026/install.sh | sudo bash
```

The installer:

1. Checks the system and installs Docker and Docker Compose when they are missing.
2. Creates `/opt/forumrexar` with a `docker-compose.yml`.
3. Pulls `forumrexar/forumrexar:latest` and starts the forum on port **38980** (chosen so it does not clash with an existing web server on 80/443).
4. Prints the address to open. The first visit opens the setup wizard, where you choose the forum's name, language and director account.

The installer source is in this repository: [../install.sh](../install.sh).

### With a domain and SSL

Point your domain's DNS to the server first, then run:

```bash
curl -sSL https://forum.rexar.net/cdn/2026/install.sh | sudo REXAR_DOMAIN=forum.example.com REXAR_EMAIL=you@example.com bash
```

The installer sets up Nginx in front of the forum and a free Let's Encrypt certificate that renews by itself. You can also run the installer again later, with these two values, to add a domain to an existing installation — your data is kept.

## Docker Compose by hand

```yaml
services:
  forumrexar:
    image: forumrexar/forumrexar:latest
    container_name: forumrexar
    restart: unless-stopped
    ports:
      - "38980:8080"
    volumes:
      - ./data:/app/data
      - ./uploads:/app/web/static/uploads
    environment:
      - PORT=8080
      - APP_ENV=production
      - APP_NAME=ForumREXAR
      - TZ=Asia/Riyadh
```

```bash
docker compose up -d
```

## Where your data lives

| Folder | What is in it |
| --- | --- |
| `data/` | The forum's database, settings, chat data, logs and backups |
| `uploads/` | Images and files members upload |

Back up both folders. The control panel can also make a backup copy at any time.

## Updating

```bash
cd /opt/forumrexar
docker compose pull && docker compose up -d --force-recreate
```

The update keeps your data; new database changes are applied automatically on start.

## Useful commands

```bash
cd /opt/forumrexar
docker compose logs -f        # follow the logs
docker compose restart        # restart the forum
docker compose down           # stop the forum
```
