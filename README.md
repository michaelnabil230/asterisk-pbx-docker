# Asterisk + MySQL Docker Stack

A Dockerized [Asterisk](https://asterisk.org/) 23.4.0 PBX with MySQL 8.0 realtime configuration, WebRTC (WSS) support, and phpMyAdmin for database management.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Docker Network                    │
│                                                     │
│  ┌──────────┐   ┌──────────────┐   ┌────────────┐   │
│  │  MySQL   │◄──│   Asterisk   │   │ phpMyAdmin │   │
│  │  8.0     │   │  23.4.0      │   │            │   │
│  │ :3306    │   │ :5060/5061   │   │ :8080      │   │
│  │          │   │ :8088/8089   │   │            │   │
│  │          │   │ :10000-10199 │   │            │   │
│  └──────────┘   └──────────────┘   └────────────┘   │
│       ▲                  │                          │
│       │    ODBC + SQLAlchemy (Alembic migrations)   │
│       └──────────────────┘                          │
└─────────────────────────────────────────────────────┘
```

## Services

| Service | Image | Port | Description |
|---|---|---|---|
| `mysql` | `mysql:8.0` | `3306` | Database for Asterisk realtime config |
| `asterisk` | Custom (`Dockerfile`) | `5060`, `5061`, `8088`, `8089`, `10000-10199` | Asterisk PBX with PJSIP, WebRTC, and ODBC |
| `phpmyadmin` | `phpmyadmin/phpmyadmin` | `8080` | Web UI for MySQL management |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) 20.10+
- [Docker Compose](https://docs.docker.com/compose/install/) v2+
- [mkcert](https://github.com/FiloSottile/mkcert) (for local TLS certificates)

## Quick Start

1. **Configure environment variables:**

   Edit `.env` with your desired credentials:

   ```env
   MYSQL_ROOT_PASSWORD=root
   MYSQL_DATABASE=asterisk
   MYSQL_USER=asterisk
   MYSQL_PASSWORD=root
   ```

2. **Generate TLS certificates** (required for WSS/WebRTC):

   ```bash
   make certs
   ```

   This uses `mkcert` to create trusted local certificates in `certs/`.

3. **Build and start the stack:**

   ```bash
   make build
   make up
   ```

4. **Seed the database** with sample SIP endpoints (1001, 1002):

   ```bash
   make db < base.sql
   ```

   Or use phpMyAdmin at [http://localhost:8080](http://localhost:8080).

## Usage

### Common Commands

```bash
make build           # Build the Asterisk image
make up              # Start all services (detached)
make down            # Stop all services
make restart         # Restart all services
make logs            # Tail logs for all services
make ps              # Show running containers
make shell           # Open a shell in the Asterisk container
make asterisk-cli    # Attach to Asterisk CLI
make db              # Open MySQL CLI
make phpmyadmin-logs # Tail phpMyAdmin logs
```

### Sample SIP Endpoints

The `base.sql` file creates two WebRTC-enabled endpoints:

| Extension | Username | Password | Transport |
|---|---|---|---|
| 1001 | `1001` | `Password1001` | WSS |
| 1002 | `1002` | `Password1002` | WSS |

Both endpoints are configured for WebRTC with DTLS-SRTP, Opus/ULaw codecs, and ICE support. They can call each other via the `from-internal` dialplan context.

### Connecting a WebRTC Client

1. Ensure certificates are generated and the stack is running.
2. Point a WebRTC SIP client (e.g., [SIP.js](https://sipjs.com/), [JsSIP](https://jssip.net/)) to:
   - **WSS URL:** `wss://localhost:8089/ws`
   - **SIP Domain:** `localhost`
3. Register as `1001` and call `1002` (or vice versa).

## Project Structure

```
.
├── docker-compose.yml      # Service orchestration
├── Dockerfile              # Asterisk build (from source)
├── docker-entrypoint.sh    # Startup: run Alembic migrations, launch Asterisk
├── .env                    # Environment variables (credentials)
├── base.sql                # Sample SIP endpoint seed data
├── Makefile                # Convenience commands
├── configs/                # Asterisk & ODBC configuration (bind-mounted)
│   ├── extensions.conf     # Dialplan
│   ├── http.conf           # HTTP/TLS server settings
│   ├── pjsip.conf          # PJSIP transport (WSS)
│   ├── res_odbc.conf       # ODBC resource config
│   ├── extconfig.conf      # Realtime backend mapping
│   ├── sorcery.conf        # Sorcery data layer config
│   ├── odbc.ini            # ODBC DSN
│   └── odbcinst.ini        # ODBC driver config
├── certs/                  # TLS certificates (generated via mkcert)
└── recordings/             # Call recordings (bind-mounted)
```

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| `3306` | TCP | MySQL |
| `5060` | UDP/TCP | SIP signaling |
| `5061` | TCP | SIP TLS |
| `8080` | TCP | phpMyAdmin |
| `8088` | TCP | Asterisk HTTP (WebSocket) |
| `8089` | TCP | Asterisk HTTPS (WSS for WebRTC) |
| `10000-10199` | UDP | RTP media (audio/video) |

## How It Works

### Startup Flow (`docker-entrypoint.sh`)

1. Copies Alembic config templates from the Asterisk source.
2. Injects the `DATABASE_URL` into each Alembic config.
3. Runs Alembic migrations to create all required Asterisk realtime tables.
4. Launches Asterisk as the `asterisk` user.

### Database

Asterisk uses MySQL for **realtime configuration** — SIP endpoints, AORs, and auth entries are stored in the database (tables `ps_endpoints`, `ps_aors`, `ps_auths`) rather than in flat files. The ODBC driver (`odbc-mariadb`) provides the connection layer.

## Troubleshooting

<details>
<summary><b>Asterisk won't start / migrations fail</b></summary>

Ensure MySQL is fully up before Asterisk starts. The `depends_on` directive only waits for container start, not readiness. Restart the asterisk service:

```bash
docker compose restart asterisk
```

</details>

<details>
<summary><b>WSS connection fails</b></summary>

1. Verify certificates exist in `certs/` (`make certs`).
2. Ensure `mkcert` root CA is trusted on your system (`mkcert -install`).
3. Check that port `8089` is accessible and not firewalled.
4. Browser must trust the certificate — use `mkcert`-generated certs or accept the self-signed warning.

</details>

<details>
<summary><b>One-way audio or no audio</b></summary>

- Ensure RTP ports `10000-10199/udp` are open in your firewall.
- For NAT environments, verify `external_media_address` in `configs/pjsip.conf`.

</details>
