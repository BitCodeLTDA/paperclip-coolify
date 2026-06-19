# Paperclip Coolify Deploy

Self-hosted [Paperclip](https://paperclip.ing) deployment for [Coolify](https://coolify.io), built from source and configured for a public authenticated deployment.

## What's included

- Paperclip server built from the [paperclipai/paperclip](https://github.com/paperclipai/paperclip) source with the `pi` CLI baked in
- PostgreSQL 16 sidecar
- Traefik labels for Coolify reverse proxy + SSL
- Persistent volumes for Paperclip data and Postgres data
- Provider API key passthrough for Paperclip local adapters and `pi-local` agents

## Requirements

- A Coolify instance
- A domain pointed at your Coolify server
- At least 4 GB RAM / 2 vCPU (8 GB RAM recommended for building Paperclip from source)
- Coolify v4.0.0-beta.411 or newer if you use Coolify magic values for secrets

## Build source

The Dockerfile clones and builds Paperclip from source rather than using a prebuilt image. Defaults are pinned for repeatable builds and can be overridden with Docker build args.

| Build arg | Default | Description |
|---|---|---|
| `PAPERCLIP_REPO` | `https://github.com/paperclipai/paperclip.git` | Git repository to clone |
| `PAPERCLIP_REF` | `a0f7d3dabaf5308ade45cae0c64ebd133948dca2` | Paperclip commit SHA for release `v2026.609.0` |
| `NODE_IMAGE` | pinned `node:lts-trixie-slim` digest | Base image |
| `USER_UID` | `1000` | UID for the `node` user inside the container |
| `USER_GID` | `1000` | GID for the `node` user inside the container |
| `PI_CODING_AGENT_VERSION` | `0.79.6` | `@earendil-works/pi-coding-agent` version |

In Coolify you can set build arguments under **Resource → Configuration → Build Args**.

## Automated updates

This repo includes lightweight GitHub automation:

- `.github/workflows/update-components.yml` runs daily and on manual dispatch.
- It checks the latest Paperclip GitHub release, `node:lts-trixie-slim` digest, and bundled CLI npm packages.
- If anything changed, it updates the pinned defaults, validates the Dockerfile and compose config, and opens a pull request.
- `.github/dependabot.yml` keeps the GitHub Actions used by the automation up to date.

## Environment variables

Set these in Coolify → Resource → Environment. The compose file references each variable explicitly so Coolify will display them in the UI.

### Required public deployment variables

| Variable | Required | Description |
|---|---|---|
| `PAPERCLIP_FQDN` | yes | Public hostname only, e.g. `paperclip.example.com`. Used by Traefik routing. |
| `PAPERCLIP_PUBLIC_URL` | recommended | Full public URL, e.g. `https://paperclip.example.com`. Defaults to `https://${PAPERCLIP_FQDN}`. |
| `PAPERCLIP_DEPLOYMENT_MODE` | no | Defaults to `authenticated`. |
| `PAPERCLIP_DEPLOYMENT_EXPOSURE` | no | Defaults to `public`. |
| `PAPERCLIP_AUTH_BASE_URL_MODE` | no | Defaults to `explicit`, required for public authenticated Paperclip. |

### Required secrets

Use Coolify magic values for first deploy, or provide your own secure values.

| Variable | Required | Recommended Coolify value | Description |
|---|---:|---|---|
| `BETTER_AUTH_SECRET` | yes | `$SERVICE_HEX_64_BETTERAUTH` | Better Auth signing secret. |
| `PAPERCLIP_AGENT_JWT_SECRET` | yes | `$SERVICE_HEX_64_AGENTJWT` | Separate secret for Paperclip local agent JWTs. |
| `POSTGRES_PASSWORD` | yes | `$SERVICE_PASSWORD_64_POSTGRES` | PostgreSQL password. Use the symbol-free magic value because this password is embedded in `DATABASE_URL`. |

### Provider API keys passed through to agents

These are optional. Any value set in Coolify is passed into the Paperclip container and inherited by child agent processes, including the `pi-local` adapter. This lets `pi` see the same API keys you configured in Coolify.

Common keys:

| Provider/use | Environment variable |
|---|---|
| Anthropic / Claude | `ANTHROPIC_API_KEY` |
| OpenAI / Codex | `OPENAI_API_KEY` |
| Gemini | `GEMINI_API_KEY` or `GOOGLE_API_KEY` |
| OpenRouter | `OPENROUTER_API_KEY` |
| Kimi For Coding | `KIMI_API_KEY` |
| DeepSeek | `DEEPSEEK_API_KEY` |
| Groq | `GROQ_API_KEY` |
| Mistral | `MISTRAL_API_KEY` |
| xAI | `XAI_API_KEY` |
| Cerebras | `CEREBRAS_API_KEY` |
| NVIDIA NIM | `NVIDIA_API_KEY` |
| Fireworks | `FIREWORKS_API_KEY` |
| Together AI | `TOGETHER_API_KEY` |
| Vercel AI Gateway | `AI_GATEWAY_API_KEY` |
| ZAI | `ZAI_API_KEY`, `ZAI_CODING_CN_API_KEY` |
| MiniMax | `MINIMAX_API_KEY`, `MINIMAX_CN_API_KEY` |
| Azure OpenAI | `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_BASE_URL`, `AZURE_OPENAI_RESOURCE_NAME`, `AZURE_OPENAI_API_VERSION`, `AZURE_OPENAI_DEPLOYMENT_NAME_MAP` |
| Cloudflare AI | `CLOUDFLARE_API_KEY`, `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_GATEWAY_ID` |
| Amazon Bedrock | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_REGION`, `AWS_ENDPOINT_URL_BEDROCK_RUNTIME` |

## Deploy

1. Push this repo to GitHub.
2. In Coolify, create a **New Resource → Application → Public Repository**.
3. Use your fork/repo URL.
4. Select **Docker Compose** build pack.
5. Base compose file: `docker-compose.yml`.
6. Set `PAPERCLIP_FQDN` to your public hostname.
7. Set the required secrets. For Coolify-generated secrets, use the magic values listed above.
8. Add any provider API keys you want Paperclip or pi agents to use, such as `KIMI_API_KEY`, `OPENROUTER_API_KEY`, `OPENAI_API_KEY`, or `ANTHROPIC_API_KEY`.
9. Deploy.

## First run

1. Open `https://${PAPERCLIP_FQDN}`.
2. Click **Claim instance admin**.
3. Create an account and finish onboarding.

## CLI fallback

If needed, exec into the running container and use the source-built CLI wrapper baked into the image:

```bash
docker exec -it <container-name> paperclipai auth bootstrap-ceo
```

Then open the printed invite URL.
