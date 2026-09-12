# Deployment — AcadNova

This describes the **actual** stack (static site + Supabase), not a generic template. Skip any
section from a generic deployment checklist that assumes a Node/Python server process — this
app doesn't have one, by design.

## 1. Required accounts/services

- **GitHub** (free) — hosts the code, triggers auto-deploy.
- **Netlify** (free tier) — hosts the static site, provides HTTPS + CDN + custom domain support.
- **Supabase** (free tier) — hosted Postgres database + authentication.
- A **domain name**, if you want one (optional — Netlify gives you a free `*.netlify.app`
  subdomain either way).

## 2. Environment variables

There are exactly two, and they live directly in `index.html` (near the top of the `<script>`
tag) rather than in a `.env` file, because this is a static site with no build step to inject
them at:

```js
const SUPABASE_URL = "...";
const SUPABASE_ANON_KEY = "...";
```

**Why this is safe:** the Supabase *anon* key is meant to be public — it's designed to sit in
client-side code. Actual data protection comes from Row Level Security policies (in
`supabase/setup.sql`), which restrict every user to their own rows regardless of what the anon
key can see. The key you must **never** put here is the Supabase *service_role* key — that one
bypasses Row Level Security entirely and belongs only in a real backend, which this project
doesn't have.

An `.env.example`-style file isn't meaningful here since there's no build process to read one;
this section is that documentation instead.

## 3. Database setup (Supabase)

1. Create a project at supabase.com (free tier).
2. Open **SQL Editor → New query**, paste the entire contents of `supabase/setup.sql`, click
   **Run**. This creates the `professor_contacts` table and locks it down with Row Level
   Security so each user only ever sees their own messages.
3. Open **Project Settings → API**, copy the **Project URL** and **anon public** key.

## 4. Frontend deployment (Netlify, Git-connected)

This replaces manual drag-and-drop with automatic deploy-on-push:

1. Push this folder to a new GitHub repository.
2. In Netlify: **Add new site → Import an existing project → GitHub** → pick the repo.
3. Build settings: leave the build command **empty** and set the publish directory to `.`
   (there's nothing to build — `netlify.toml` already encodes this, so Netlify should
   auto-detect it).
4. Deploy. Netlify gives you a URL like `https://random-name-123.netlify.app` immediately.
5. From now on, every `git push` to the main branch automatically redeploys the live site —
   no manual file upload, ever again.

## 5. Backend

There isn't a separate backend deployment step — Supabase *is* the backend, and it's already
running the moment you created the project in step 3. No server to start, no process to keep
alive, no restart policy to configure.

## 6. HTTPS

Automatic. Netlify issues and renews an SSL certificate for you, serves everything over HTTPS,
and redirects any HTTP request to HTTPS. Nothing to configure.

## 7. Custom domain

1. In Netlify: **Site settings → Domain management → Add a domain**, enter your domain.
2. Netlify shows you the exact DNS records to add (typically an `A`/`ALIAS` record for the
   apex domain and a `CNAME` for `www`). Add those at your domain registrar.
3. Netlify auto-provisions HTTPS for the custom domain once DNS propagates (can take up to a
   few hours).

```
Domain registrar (DNS records) → Netlify → this repo's index.html → Supabase (auth + database)
```

There's no separate `api.yourdomain.com` to configure — Supabase's own hosted URL is the API
endpoint, called directly from the browser.

## 8. Routing / deep links

`netlify.toml` includes an SPA fallback redirect (`/* → /index.html`, status 200). This is what
makes `/universities/eth-zurich` or `/professors/eth-zurich--andreas-krause` work on a fresh
load or a refresh — Netlify serves `index.html` for any path, and the app's own router
(`applyRouteFromLocation()` in `index.html`) reads the URL and restores the right view.

## 9. Background jobs / data refresh

Not implemented in this project yet. The seeded university/ranking/professor data is static
inside `index.html`. `ingestion_pipeline.md` (from the earlier planning round) describes the
scheduled-crawler architecture this would need for continuous real-world data refresh — that's
a genuinely separate, larger build (it needs a real backend to run scheduled jobs, which this
static-site architecture intentionally doesn't have).

## 10. Health checks / monitoring

- **Site up/down:** Netlify's own status dashboard, or an external uptime monitor (e.g. a free
  UptimeRobot check against your homepage) — there's no custom `/health` endpoint to build
  because there's no custom server.
- **Database:** Supabase's dashboard shows connection/query health directly.
- **Errors:** none currently captured centrally. For real production use, add a client-side
  error reporting snippet (e.g. Sentry's browser SDK) — not included yet, ask if you want it.

## 11. Backups

Supabase's free tier does **not** include automatic backups — only paid tiers do. If the data
in `professor_contacts` (user messages) matters long-term, either upgrade the Supabase plan for
automatic backups, or periodically export the table (Table Editor → Export as CSV).

## 12. Troubleshooting

| Symptom | Likely cause |
|---|---|
| "Backend not connected" banner never disappears | `SUPABASE_URL`/`SUPABASE_ANON_KEY` still say `PASTE_YOUR_...` |
| Register/login does nothing, no error | Check browser console — usually a copy-paste error in the Supabase keys |
| Messages don't show up in "My Outbox" | Confirm `supabase/setup.sql` actually ran (check Table Editor for `professor_contacts`) |
| Refreshing `/professors/...` shows a blank/home page | `netlify.toml` redirect isn't active — confirm it deployed (check Netlify's deploy log) |
| Custom domain shows "not secure" | DNS hasn't propagated yet, or the domain hasn't been added in Netlify's domain settings |

## 13. Updating production

```
edit index.html → git commit → git push
```
That's the entire update process. Netlify rebuilds and redeploys automatically within roughly a
minute of the push.
