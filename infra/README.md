# infra — Deployment & Infrastructure

Everything WaiveGO's backend needs (CompreFace for facial recognition, plus WaiveGO's own
database) is meant to run as one Docker Compose stack on a single DigitalOcean Droplet for
now. `apps/web` (the dashboard) can deploy separately later (e.g. Vercel) — this doc only
covers the Droplet.

## Why one Droplet is fine (for now)

A single waterpark's daily check-in volume doesn't need more than this. The trade-off is a
single point of failure — if the Droplet goes down, both check-in and the admin dashboard's
backend go down together. Acceptable while validating the system; revisit (split CompreFace
onto its own Droplet, move to DigitalOcean Managed Postgres, add a second Droplet behind a
load balancer) once real traffic and uptime expectations justify it.

## 1. Create the Droplet

- **Size**: start with the "Basic" 4GB RAM / 2 vCPU Droplet. CompreFace alone (Postgres + two
  JVM services + a Python/TensorFlow inference service) is the heavy part; resize to 8GB/4vCPU
  later if things feel sluggish — a few minutes of downtime on DigitalOcean, not a rebuild.
- **Image**: choose the "Docker" one-click app image (Marketplace) so Docker + Docker Compose
  are preinstalled, or a plain Ubuntu LTS image and install Docker yourself.
- **Networking**: put it in a **VPC** (DigitalOcean creates a default one per region) — this
  is what lets you lock things down in step 3.
- **Region**: pick whichever is closest to the waterpark for lowest latency from the iPad.

## 2. First-time server setup

```bash
ssh root@<droplet-ip>

# if you didn't use the Docker marketplace image:
curl -fsSL https://get.docker.com | sh

# clone just what's needed, or scp infra/ up — either works
git clone https://github.com/boywonder0806/WaiveGO.git
cd WaiveGO/infra
cp .env.example .env
nano .env   # fill in real passwords — long, random, unique per field
```

## 3. Lock down the firewall

CompreFace and both Postgres instances are only reachable from other containers on the
`backend` Docker network — nothing to open for them. `waivego-api` publishes a port, but only
to loopback (`127.0.0.1`), so it isn't reachable externally either yet. Lock the Droplet's own
firewall down explicitly anyway (defense in depth, and to prepare for going public later):

- DigitalOcean Cloud Firewall (or `ufw` on the box): allow inbound **22 (SSH)** from your IP
  only. Once `waivego-api` is ready to go public (domain + TLS + auth — see step 6), that's
  when **80/443** gets opened too; nothing else should ever need to be.
- Deny everything else inbound by default.

## 4. Bring the stack up

```bash
cd WaiveGO/infra
docker compose up -d
docker compose ps        # confirm all containers are healthy/running
docker stats             # watch actual memory use against the mem_limits — if
                          # something is consistently near its cap, that's your
                          # signal to resize the Droplet before it OOMs
```

CompreFace's admin UI has no public port by design (see the comment in `docker-compose.yml`).
To reach it for initial setup (creating your admin account, an application, and a face
collection), tunnel it over SSH instead of exposing it:

```bash
# on the Droplet — add a loopback-only port (not committed to git; a
# docker-compose.override.yml is picked up automatically alongside docker-compose.yml):
cat > docker-compose.override.yml << 'EOF'
services:
  compreface-fe:
    ports:
      - "127.0.0.1:8000:80"
EOF
docker compose up -d compreface-fe

# from your own machine:
ssh -L 8000:localhost:8000 root@<droplet-ip>
# open http://localhost:8000 in your browser, create your admin account, an
# Application, and a Face Collection service inside it — CompreFace generates an
# API key for that service; save it into .env as compreface_recognition_api_key
# (see .env.example for the exact key name)

# back on the Droplet, once you're done:
rm docker-compose.override.yml
docker compose up -d compreface-fe   # recreates it without the port — confirm with
                                      # `docker port compreface-ui` (should print nothing)
```

## 5. waivego-api

Built from `services/api`'s `Dockerfile`, on the `backend` network so it reaches
`compreface-ui` and `waivego-db` by container name — no tunneling needed for it to talk to
either of those. It's already in `docker-compose.yml`; rebuild after pulling changes:

```bash
cd WaiveGO/infra
git pull
docker compose build waivego-api
docker compose up -d waivego-api
```

Its own port is loopback-only (`127.0.0.1:3001`) — same reasoning as CompreFace's admin UI
above (no auth on it yet, and it carries guest photos that shouldn't cross plain HTTP). Reach
it the same way, via SSH tunnel:

```bash
ssh -L 3001:localhost:3001 root@<droplet-ip>
curl http://localhost:3001/health
```

## 6. Next steps (not done yet)

- Put a reverse proxy (Caddy is the easiest — automatic HTTPS via Let's Encrypt with a few
  lines of config) in front of `waivego-api`, get a domain pointed at the Droplet, and add
  auth to its endpoints (see `services/api/README.md`'s known gaps) — all three needed before
  its port can move from loopback-only to actually public, which is what the iPad needs for
  real (tunneling doesn't scale to a kiosk device on the guest network).
- Set up automated backups: DigitalOcean Droplet snapshots cover the whole box; for
  point-in-time recovery of just the databases, `pg_dump` both Postgres containers on a cron
  schedule to DigitalOcean Spaces (or similar) instead.
