# Paperclip Coolify Deploy

Self-hosted [Paperclip](https://paperclip.ing) deployment for [Coolify](https://coolify.io).

## What's included

- Paperclip server from `ghcr.io/ben-ranford/paperclip` with the `pi` CLI baked in
- PostgreSQL 16 sidecar
- Traefik labels for Coolify reverse proxy + SSL
- Persistent volumes for Paperclip data and Postgres data

## Requirements

- A Coolify instance
- A domain pointed at your Coolify server
- At least 2 GB RAM / 2 vCPU (4 GB RAM recommended for builds)

## Environment variables

Set these in Coolify → Resource → Environment:

| Variable | Required | Description |
|---|---|---|
| `BETTER_AUTH_SECRET` | yes | Strong random secret (`openssl rand -hex 32`) |
| `POSTGRES_PASSWORD` | yes | Strong database password |
| `OPENAI_API_KEY` | no | For Codex adapter |
| `ANTHROPIC_API_KEY` | no | For Claude adapter |
| `GEMINI_API_KEY` | no | For Gemini adapter |

`COOLIFY_URL` and `COOLIFY_DOMAIN` are injected automatically by Coolify.

## Deploy

1. Push this repo to GitHub.
2. In Coolify, create a **New Resource → Application → Public Repository**.
3. Use your fork/repo URL.
4. Select **Docker Compose** build pack.
5. Base compose file: `docker-compose.yml`.
6. Add the required environment variables.
7. Expose port `3100` and add your domain in Coolify Settings.
8. Deploy.

## First run

1. Open your domain.
2. With `PAPERCLIP_DEPLOYMENT_EXPOSURE=private`, click **Claim instance admin**.
3. Create an account and finish onboarding.

## CLI fallback

If needed, exec into the running container:

```bash
docker exec -it <container-name> bash
npx paperclipai auth bootstrap-ceo
```

Then open the printed invite URL.
