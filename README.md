# AcadNova — Global Academic & Research Discovery

Browse verified foreign university rankings and AI/ML/engineering research domains, discover
professors with source-linked profiles, and message them directly. India and China are
excluded from the discovery database by design. See `DEPLOYMENT.md` for how the production
site is hosted and how to update it.

## What this actually is (read this first)

A single static file (`index.html`) — no build step, no bundler, no backend server process.
All data browsing runs entirely in the browser. Accounts and messages are handled by
**Supabase** (a hosted Postgres database + auth service) called directly from the browser.
There is nothing to "start" — see `DEPLOYMENT.md` for why that's true in production.

## Local development

There isn't really a separate "dev mode" to run — because there's no build step, local
development *is* just opening the file:

1. Open `index.html` directly in a browser (double-click it), **or**
2. Serve the folder locally so relative behavior matches production exactly:
   ```
   npx serve .
   ```
   then open the printed `http://localhost:...` URL.

Either way, if `SUPABASE_URL` / `SUPABASE_ANON_KEY` near the top of `index.html`'s `<script>`
are filled in, registration/login/messaging work locally too, against the **same** database as
production — Supabase doesn't have a separate "local" vs "production" instance for this project.
If you want a genuinely separate dev database, create a second free Supabase project and swap
the keys before testing.

## Production

The live site is a static deploy on Netlify, connected to this repository, with a Supabase
project as the backend. See `DEPLOYMENT.md` for full setup and how updates get published.

## Project structure

```
index.html          the entire application (frontend + routing + Supabase calls)
netlify.toml         deploy config: SPA routing, security headers
supabase/setup.sql   run once in the Supabase SQL editor to create the messages table + security rules
robots.txt, sitemap.xml   basic SEO
```

## Data honesty note

University rankings and professor records in `index.html` are real and source-linked (see the
`RANKING_SOURCE` and each professor's `official_profile`/`group_page` fields). Rank slots and
universities with no seeded record are shown as "pending ingestion," never fabricated. See
`data_model.md` and `ingestion_pipeline.md` (from the earlier planning round) for how this
would scale to full global coverage.
