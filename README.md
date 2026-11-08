# Deploying MyApp to a client's Windows PC

> **Set up for the hotel app (hotel-frontend-next + hotel-backend).** Where this differs from the generic guide below:
>
> - The Dockerfiles and CI workflows live in the two repos (Part B, Option 2). This kit's `frontend/` and `backend/` folders are the unused generic templates. `release.sh` builds straight from the repos.
> - Images: `ghcr.io/sawyeyintaung/hotel-frontend` and `hotel-backend`.
> - **Skip A2 and A3.** The browser never calls the backend, so there's no `NEXT_PUBLIC_API_URL`, no port 4000 and no published backend port. The frontend's server uses `API_URL=http://backend:8000/api`. The backend migrates the database itself on every start (Prisma 8, `db migrate --to db`).
> - `client-package/.env` needs more keys than C2 lists. See `client-package/.env.example`, especially **`BETTER_AUTH_SECRET`** (`openssl rand -hex 32`); compose refuses to start without it.
> - After the first install, run **`create-admin.bat`** on the client PC to make the first admin. Optionally run `docker compose exec backend npm run db:seed` for the hotel's room types, rooms, service rates and payment methods.
> - Using it from other PCs: add `http://<client-PC-IP>:3000` to `CORS_ORIGIN` in `.env`. No rebuild needed.

Next.js + Express + PostgreSQL, running in Docker on the client's own computer.
The images go through GitHub Container Registry (GHCR, free private images).

```
YOUR MACHINE                       GHCR (cloud)                 CLIENT PC
release.sh  --- build & push --->  myapp-frontend   <--- pull --- install.bat / update.bat
                                   myapp-backend                  (Docker Desktop runs it)
```

Folder layout this package expects:

```
hotel-deploy/
├─ frontend/        <- your Next.js app + Dockerfile + .dockerignore
├─ backend/         <- your Express app + Dockerfile + .dockerignore
├─ client-package/  <- what you zip and send to the client
├─ release.sh       <- Mac/Linux (or Git Bash on Windows)
└─ release.bat      <- Windows
```

Copy your app's code into `frontend/` and `backend/`, keeping the Dockerfiles I made.

---

## Part A: one-time setup on your machine

### A1. Install Docker
Install Docker Desktop (Mac/Windows) or Docker Engine (Linux).

### A2. Prepare the Next.js app
In `next.config.js` / `next.config.mjs` / `next.config.ts`:

```js
const nextConfig = { output: 'standalone' };
```

Without this setting, the frontend image won't build. If you have no `public/` folder, create an empty one.

Use the two API URLs:
- In **browser** code: `process.env.NEXT_PUBLIC_API_URL` (baked in at build time, `http://localhost:4000`)
- In **server** code (SSR, server actions, route handlers): `process.env.API_URL_INTERNAL` (`http://backend:4000`)

### A3. Prepare the Express app
- `package.json` must have a `"start"` script, e.g. `"start": "node index.js"`
  (with TypeScript: `"build": "tsc"` and `"start": "node dist/index.js"`).
- Listen on `process.env.PORT` (4000).
- Connect with `process.env.DATABASE_URL`.
- Enable CORS for `http://localhost:3000`, because the browser calls port 4000 from port 3000:
  ```js
  app.use(require('cors')({ origin: 'http://localhost:3000' }));
  ```
- **Create the tables when the app starts** (run your migrations on startup, e.g. Prisma
  `prisma migrate deploy`, Knex `migrate.latest()`, or `CREATE TABLE IF NOT EXISTS`).
  The client's database starts empty, and nobody will run migrations by hand.

### A4. Test locally first
Use the dev `docker-compose.yml` from earlier (`build:` version) and run
`docker compose up --build`. Fix everything here before involving the client.

### A5. Create a GitHub token for pushing
GitHub → Settings → Developer settings → Personal access tokens → **Tokens (classic)** →
Generate new token → tick **`write:packages`** → copy it.

```bash
echo YOUR_PUSH_TOKEN | docker login ghcr.io -u your-github-username --password-stdin
```

### A6. Edit the release script
In `release.sh` (or `release.bat`), set `OWNER` to your GitHub username, **all lowercase**.

---

## Part B: release a version

### Option 1: manually from your machine

```bash
chmod +x release.sh      # first time only
./release.sh 1.0.0       # Windows: release.bat 1.0.0
```

This builds both images for `linux/amd64` (normal Windows PCs; works even from an
Apple Silicon Mac) and pushes two tags each: `1.0.0` and `latest`.

Check that they appear at `https://github.com/your-github-username?tab=packages`.
They are **private** by default. Keep them that way.

### Option 2: automatic with GitHub Actions (two repos)

With CI, GitHub builds the images for you, so you don't need `release.sh` or a push token.

1. Each repo should have its `Dockerfile` and `.dockerignore` in the **repo root**.
2. Copy the workflow files:
   - `ci/frontend-repo/.github/workflows/docker-publish.yml` → frontend repo, same path
   - `ci/backend-repo/.github/workflows/docker-publish.yml` → backend repo, same path
3. Both repos must belong to the **same GitHub account or organization**, because the
   client's `.env` has one `GHCR_OWNER`.
4. (Optional) In the frontend repo: Settings → Secrets and variables → Actions →
   **Variables** → add `API_URL`. Without it, `http://localhost:4000` is used.
5. Push to `main`. You can watch it run in the **Actions** tab (about 2–5 min).

What gets pushed:

| You do | Image tags |
|---|---|
| push to `main` | `latest` + `sha-abc1234` |
| `git tag v1.2.0 && git push --tags` | `1.2.0` + `sha-abc1234` |

The client's `update.bat` always pulls `latest`, so **anything merged to `main` reaches
the client on their next update**. Protect `main` (require a PR) and test before merging.
To roll back, set `APP_VERSION` in the client's `.env` to a version tag or `sha-abc1234`.

> Note: with two repos, `latest` frontend and backend can be from different moments.
> If an update changes the API in both, merge the backend first, wait for its build to
> finish, then merge the frontend, and only then tell the client to update.

**Package access:** images pushed by Actions are private and owned by your account, so
the client's `read:packages` token from Part C can pull them. If you push under an
**organization**, create that token on an account that is a member of the org.

---

## Part C: prepare the client package (first time only)

### C1. Create a read-only token for the client
New classic token, tick **only `read:packages`**, no expiry (or a long one).
This token can only *download* your images. It can't change anything.

### C2. Fill in `client-package/.env`
```
GHCR_OWNER=your-github-username
GHCR_USER=your-github-username
GHCR_TOKEN=ghp_the_read_only_token
POSTGRES_PASSWORD=SomeStrongPassword123
```
Use only letters and numbers (no `& % ! ^` or spaces), because the .bat scripts read this file.
**Never change `POSTGRES_PASSWORD` after the first install.** Postgres keeps the original
password, and the backend will fail to connect.

### C3. Zip and send
Zip the whole `client-package` folder (make sure the hidden `.env` file is included) and
share it via Google Drive. Tell the client to follow `READ-ME-FIRST.txt`.

---

## Part D: what the client does

1. Extracts to `C:\MyApp`.
2. Double-clicks `install.bat`. On the first run it installs Docker Desktop via winget.
   The client then restarts, opens Docker Desktop once, clicks Accept, and runs
   `install.bat` again.
3. The second run: logs in to GHCR → pulls images → starts everything → creates a
   **MyApp** desktop shortcut → schedules a daily backup at 12:00 → opens the browser.

After that, the app starts automatically with Windows (Docker Desktop autostart +
`restart: unless-stopped`). The desktop shortcut also starts Docker if needed.

> Docker Desktop needs hardware virtualization and WSL 2. On most modern PCs it works
> out of the box. If Docker shows a "virtualization" error, it must be enabled in the BIOS.
> That's a one-time job for you or a technician, not the client.

---

## Part E: shipping updates

1. You: `./release.sh 1.1.0`
2. Tell the client: "double-click **update.bat**".
   It backs up the database first, then pulls `latest`, restarts, and cleans old images.

**Roll back:** set `APP_VERSION=1.0.0` in the client's `.env`, then run `update.bat`.

You only resend the zip if `docker-compose.yml` or the scripts change. In that case,
tell the client to replace the files but **keep the `backups` folder and `.env`**.

---

## Part F: backups

- `backup.bat` runs daily at 12:00 (when the PC is on) and before every update.
- Files go to `C:\MyApp\backups\backup-YYYY-MM-DD_HHMM.sql`. Files older than 30 days are deleted.
- **Restore:** drag a `.sql` file onto `restore.bat` and type `YES`.
- The data only exists on the client's PC. Ask them to copy `backups` to Google Drive or a USB drive regularly.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `install.bat` closes instantly | Make sure the zip was extracted. Scripts can't run from inside a zip. |
| "unauthorized" on pull | The token in `.env` is wrong or expired, or `GHCR_OWNER` isn't lowercase. |
| `exec format error` | The image was built for ARM. Rebuild with `release.sh` (it forces `linux/amd64`). |
| Page loads but API calls fail | CORS isn't enabled in Express, or `NEXT_PUBLIC_API_URL` was wrong at build time. |
| Port 3000/4000 already in use | Another program uses it. Change the left side of `ports:` in `docker-compose.yml`. |
| See logs on the client PC | In `C:\MyApp`, run `docker compose logs --tail 100 backend` |

**Using it from other PCs in the office:** browser code uses `localhost:4000`, which means
"this computer". For other devices, rebuild with `API_URL=http://<client-PC-IP>:4000`,
add that origin to CORS, and give the client PC a fixed IP.
