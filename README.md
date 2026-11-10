# hotel-client-kit

What runs the hotel app on the client's Windows PC or Mac: the `docker-compose.yml`, the install, update and backup scripts, and the client's guides. Postgres, [hotel-backend](https://github.com/sawyeyintaung/hotel-backend) and [hotel-frontend-next](https://github.com/sawyeyintaung/hotel-frontend-next) run in Docker Desktop, from **public images on Docker Hub**.

```
APP REPOS (you build + push)       DOCKER HUB (public)             CLIENT PC OR MAC
hotel-backend        ----------->  <user>/hotel-backend   <--pull-- install / update script
hotel-frontend-next  ----------->  <user>/hotel-frontend           (Docker Desktop runs it)
```

This repo is only the client side, and **it is public**: the client's computer clones it from GitHub with no login, and its update script pulls kit changes. Nothing secret is in it; the client's `.env` and `backups/` are gitignored. Each image is built and pushed from its own repo: see hotel-backend's `docs/docker.md` and hotel-frontend-next's `docs/docker.md`.

The repo has the same scripts twice: `.bat` for Windows in `windows/` (they share `_common.bat`) and `.command` for Mac in `mac/` (double-click in Finder; they share `_common.sh`). Each guide, `READ-ME-FIRST.txt` and `READ-ME-FIRST-MAC.txt`, only covers its own folder.

```
MyApp/                    the clone: C:\MyApp or ~/MyApp
  windows/                install, start, stop, update, backup, restore (.bat)
  mac/                    the same as .command files
  docker-compose.yml
  .env                    the client's settings (gitignored)
  setup/                  setup.example.json; the client's setup.json (gitignored)
  backups/                database dumps (gitignored)
  READ-ME-FIRST.txt, READ-ME-FIRST-MAC.txt
```

Every script works from `MyApp/`, one level above its own folder (`_common.bat` / `_common.sh` change to it), so `docker compose`, `.env`, `backups/` and `setup/` are always found there, wherever the script was started from. `.gitattributes` pins their line endings (CRLF for `.bat`, LF for the Mac scripts), so a clone works whatever git's settings are on that computer.

## The images are public

Anyone can pull them, so the client needs no login. No secret is inside: `.dockerignore` keeps every `.env` out, and every setting comes from the client's `.env` when the containers start. But the compiled code and migrations are readable by anyone who pulls them.

## How the containers fit together

`docker-compose.yml` runs three services as the compose project `myapp`:

```
Browser ──:3000──▶ frontend ──http://backend:8000/api──▶ backend ──db:5432──▶ db ──▶ volume myapp_pgdata
```

| Service    | Image                         | What it does                                                                                       |
| ---------- | ----------------------------- | -------------------------------------------------------------------------------------------------- |
| `db`       | `postgres:17`                 | The database. Its data lives in the `pgdata` volume, at `/var/lib/postgresql/data`.                |
| `backend`  | `<user>/hotel-backend`        | On every start: migrates the database, creates the first admins if there are none, fills an empty hotel from `setup/setup.json`, then serves the API. |
| `frontend` | `<user>/hotel-frontend`       | The app staff use. The only service with a port on the PC: `3000`.                                  |

- **Start order:** `db` must be healthy (`pg_isready`) before `backend` starts, and `frontend` starts once `backend` has *started*, not once it's ready. Right after a start or update, the app can show errors for a few seconds while the backend migrates.
- **They find each other by service name** (`db`, `backend`) on compose's private network. `backend` and `db` have no port on the PC, so nothing outside Docker can reach them.
- **All three restart by themselves** (`restart: unless-stopped`): after a crash, and when Docker Desktop starts at login. `stop.bat` / `stop.command` stops them until the start script or the shortcut runs.

### The volume holds all the hotel's data

Every guest, stay, payment and staff account is in one Docker volume, `myapp_pgdata`. The containers can be deleted and recreated, as every update does, and the data stays.

**Safe — the data stays:**

- Running `update.bat`, `start.bat` or `stop.bat` (`docker compose down`)
- Restarting the PC
- Updating the kit with `git pull` (`.env` and `backups/` are gitignored)

**Not safe — the data is lost:**

- **`docker compose down -v`** — `-v` deletes the volume. Never run it on the client PC.
- **Uninstalling Docker Desktop, or "Reset to factory defaults"** — deletes every volume.

**Looks lost, but isn't:**

- **Renaming `name: myapp` in `docker-compose.yml`** — the volume's name comes from the project name, so compose creates a new, empty `<newname>_pgdata` and the app starts on an empty database. The old data is still in `myapp_pgdata`, just unused. That's why the project and scripts still say "MyApp".

- **The `backups` folder is the only copy outside Docker.** `backup.bat` dumps the database into it daily and before every update, and `restore.bat` loads a dump back.
- **`POSTGRES_PASSWORD` (and `POSTGRES_USER` / `POSTGRES_DB`) are applied only when the volume is first created.** After that Postgres keeps them, so changing them in `.env` makes the backend fail to log in.
- **A new major Postgres version (`postgres:18`) can't open this volume.** Changing the tag needs a dump with `backup.bat`, a fresh volume and a restore with `restore.bat`. The 17 line keeps getting security fixes on the same tag.

Check the volume on the client PC with `docker volume ls` (look for `myapp_pgdata`) and its size with `docker system df -v`.

## First install at the client

You do steps 1–3 on the client's computer; the client's guide (`READ-ME-FIRST.txt`, or `READ-ME-FIRST-MAC.txt`) starts at step 4.

1. **Install git**, if it isn't there:
   - Windows: `winget install -e --id Git.Git` in a terminal, or the installer from git-scm.com. Open a new terminal afterwards.
   - Mac: run `git --version` in Terminal. If git is missing, macOS offers to install the developer tools; click Install.
2. **Clone the kit** to the folder the guides use:
   ```
   git clone https://github.com/sawyeyintaung/hotel-client-kit.git C:\MyApp     # Windows
   git clone https://github.com/sawyeyintaung/hotel-client-kit.git ~/MyApp      # Mac
   ```
   The repo is public, so this needs no login.
3. **Create `.env`** in that folder from `.env.example` (`copy .env.example .env` on Windows, `cp .env.example .env` on a Mac) and fill it in. It never comes from GitHub. Type it there, or bring it from your password manager; don't send it by chat or email.
   - `DOCKERHUB_USER`: the Docker Hub account you push the images to.
   - `POSTGRES_PASSWORD`: **never change it after the first install.** Postgres keeps the first one, and the backend would fail to connect.
   - `BETTER_AUTH_SECRET`: make one with `openssl rand -hex 32`.
   - `SEED_ADMIN_USERNAMES` and `SEED_ADMIN_PASSWORD`: the first admins. The first start creates them on the empty database, and after that they're ignored. Each admin changes the password after logging in.
   - Values use letters and numbers only (no `& % ! ^` or spaces): the scripts read this file.
   - **The hotel's setup (optional):** in the `setup` folder, copy `setup.example.json` to `setup.json` (`copy setup\setup.example.json setup\setup.json` on Windows, `cp setup/setup.example.json setup/setup.json` on a Mac). Fill in the hotel's payment methods, room types (name, pax, price), rooms (number, floor and room type by name) and service rates. The first start creates them all on the empty database. It's gitignored, like `.env`, so the prices never reach GitHub. Without it, staff enter them in the dashboard (step 6).
4. **On a Windows PC:** double-click `windows\install.bat`. The first run installs Docker Desktop. After a restart and accepting Docker's terms, run it again: it pulls the images, starts everything, adds a **MyApp** desktop shortcut and schedules a daily backup at 12:00 (Task Scheduler).
5. **On a Mac:** double-click `mac/install.command`. The first run installs Docker Desktop (with Homebrew if the Mac has it, otherwise it opens the download page). After opening Docker once and accepting its terms, run it again: it pulls the images, starts everything, puts a **MyApp** link on the desktop and schedules the daily backup at 12:00 (a launchd job, `~/Library/LaunchAgents/com.myapp.backup.plist`). Git keeps the scripts' run permission, and cloned files aren't marked as downloaded, so macOS shouldn't block them.
6. Log in as an admin. With a setup file, check the room types, rooms, service rates and payment methods are there. Without one, enter them now.

### The setup file

`setup/setup.json` is read only while the hotel is empty: each part (payment methods, room types with their rooms, service rates) only fills an empty table, so nothing entered in the app is ever overwritten. After the first start, editing or deleting the file changes nothing; change the setup in the dashboard. If the file is broken (not JSON, a missing price, a room whose type isn't in the file), the backend stops on the first start and creates nothing. The reason is in `docker compose logs backend`; fix the file and run the start script again. The backend's `docs/docker.md` has the full format.

**Keep a copy of the client's `.env`** somewhere safe, like a password manager. It's not in git, and you need it to reinstall or move to a new PC.

The app starts at login on both (Docker Desktop autostart and `restart: unless-stopped`).

> Docker Desktop needs hardware virtualization and WSL 2. If it shows a "virtualization" error, it has to be turned on in the BIOS, a one-time job for you or a technician.

## Updating the client

Once you've pushed new images (`1.2.0` and `latest`) from the app repos, tell the client to double-click **`windows\update.bat`** (Mac: **`mac/update.command`**). It:

1. **Pulls this kit from GitHub** (`git pull --ff-only`), so script and `docker-compose.yml` changes arrive too. If git is missing or the pull fails, it warns and carries on with the images.
2. Backs up the database.
3. Pulls the `latest` images and restarts. On start, the backend migrates the database by itself.

A pull can change the update script itself, so it guards against that: `update.bat` runs a copy of itself from `%TEMP%`, and `update.command` keeps its body in a function that bash reads whole before running. A changed update script takes effect from the next update.

**Roll back:** set `APP_VERSION=1.1.0` in the client's `.env` and run the update script. Both images must exist with that tag. Once the fix is released, set it back to `latest`, or every update keeps installing 1.1.0.

**Which version is the client on?** In the app's folder (`C:\MyApp`, or `~/MyApp` on a Mac). This reads the version label the build command sets:

```
docker inspect --format "{{index .Config.Labels \"org.opencontainers.image.version\"}}" myapp-backend-1
```

## Changing this kit

Commit and push to `main`. The client gets it on their next update, or right away with `git pull` in the app's folder. `.env` and `backups/` are gitignored, so a pull never touches them.

- **Everything on `main` is public and reaches every client.** Test a change on your own computer first.
- **Push images before a kit change that needs them.** An update pulls the kit first, then the images, so both arrive together; but a client who updates in between gets the new kit with the old images.
- **Don't edit kit files on a client's computer.** Per-client settings belong in their `.env`. A locally changed file makes `git pull --ff-only` refuse, and the update then warns that it couldn't update MyApp's files. Run `git status` in the app's folder to see what changed.
- **A new required setting** (a new `${NAME:?…}` in `docker-compose.yml`) must be added to every client's `.env` before their next update, or compose refuses to start. Add it to `.env.example` too.

A new environment variable the app reads goes in that app repo's `.env.example`, and in `docker-compose.yml` and `.env.example` here if the client needs it.

## Backups

- `backup.bat` / `backup.command` runs daily at 12:00 (when the computer is on and awake) and before every update, into `backups/backup-YYYY-MM-DD_HHMM.sql` in the app's folder. Files older than 30 days are deleted. On a Mac, the daily run's output goes to `backups/backup.log`.
- **Restore on Windows:** drag a `.sql` file from `backups` onto `windows\restore.bat` and type `YES`.
- **Restore on a Mac:** double-click `mac/restore.command`, pick a backup by number and type `YES`.
- The data exists only on the client's PC. Ask them to copy `backups` to Google Drive or a USB drive regularly.

## Troubleshooting

| Problem                                  | Fix                                                                                                    |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| "pull access denied" / "not found"       | `DOCKERHUB_USER` in `.env` is wrong, or the Docker Hub repository isn't public yet.                     |
| "toomanyrequests" on pull                | Docker Hub's anonymous limit (100 pulls / 6 h per IP). Wait, or `docker login` on the client PC.       |
| `exec format error` / "no matching manifest" | The image wasn't built for this computer's platform. Rebuild with `--platform linux/amd64,linux/arm64` (see the app repo's Docker doc). |
| Mac: "cannot be opened" / "can't check it for malicious software" | macOS blocks downloaded scripts once: right-click the `.command` → Open → Open. |
| Mac: "You do not have access privileges" or nothing happens | The `.command` files lost their run permission (copied instead of cloned). In Terminal: `chmod +x ~/MyApp/mac/*.command`. |
| Login page says it can't log in         | The address in the browser isn't in `CORS_ORIGIN` in `.env`.                                            |
| "Add … to .env"                          | That setting is missing or empty in `.env`. Fill it in and run the script again.                        |
| App won't open after the first install, log says "Setting up the hotel failed" | `setup/setup.json` has a mistake; the log names each one. Fix the file and run the start script again. |
| Port 3000 already in use                 | Set `FRONTEND_PORT` in `.env` to a free port (e.g. `3001`), and change the port in `APP_URL` / `CORS_ORIGIN` to match. |
| See logs on the client's computer        | In the app's folder: `docker compose logs --tail 100 backend`                                           |

**Using it from other PCs in the office:** give the client PC a fixed IP and add `http://<client-PC-IP>:3000` to `CORS_ORIGIN` in `.env`. No rebuild needed.
