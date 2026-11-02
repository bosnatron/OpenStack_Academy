Learning
OpenStack Academy

An educational website built with Perl and Dancer2, covering Linux and open-source tools.

## Lessons

1. Linux installation
2. Linux commands
3. Vim
4. Apache
5. MariaDB and MySQL
6. Perl
7. CPAN
8. Dancer2
9. Git and GitHub

The homepage also includes interactive mate-in-three chess puzzles.

## Run locally

You need Perl and the following modules:

- Dancer2
- Template Toolkit
- YAML
- Plack

If you have `cpanm`, install the dependencies from the repository directory:

```bash
cpanm --installdeps . Template YAML Plack
```

Start the application:

```bash
export DANCER_APPHANDLER=PSGI
plackup -s HTTP::Server::PSGI -Ilib \
  --host 127.0.0.1 --port 5000 bin/app.psgi
```

Open http://127.0.0.1:5000 in your browser.

No database, OpenStack installation, or application credentials are required.

## Run tests

From the repository directory:

```bash
DANCER_APPHANDLER=PSGI prove -lr t
```

The existing suite contains 13 tests across two test files.

**Note:** Set `DANCER_APPHANDLER=PSGI` when running tests. Without it, importing the application can start a development server.

## Run with Docker

The Docker deployment files are currently on the
[`codex/render-deployment`](https://github.com/bosnatron/OpenStack_Academy/tree/codex/render-deployment)
branch.

From a checkout containing those files:

```bash
docker build -t openstack-academy .
docker run --rm -p 10000:10000 openstack-academy
```

Open http://127.0.0.1:10000 in your browser.

## Deployment

The deployment branch includes:

- `Dockerfile` — installs dependencies, runs tests, and starts Starman.
- `.dockerignore` — excludes local files from the image.
- `render.yaml` — describes a Render web service using its Free plan.
- `DEPLOYMENT.md` — deployment instructions.

Hosting has been prepared and tested locally in Docker. No public deployment has been completed.

Render controls free-plan availability, account verification, and usage limits. Review its current terms before deploying. A host-provided `*.onrender.com` address can be used without purchasing a custom domain.

## Chess widget

The chess widget uses:

- Chessground and chess.js, loaded from `esm.sh`
- Chessground styles, loaded from `cdn.jsdelivr.net`
- A local puzzle catalog at `public/data/mate-in-three.json`

Browser access to those external services is required.

Puzzle data comes from the [Lichess CC0 puzzle database](https://database.lichess.org/).
See the [Chessground repository](https://github.com/lichess-org/chessground)
for its GPL-3.0-or-later license.

## Known setup issue

`Makefile.PL` references a missing `lib/MyApp.pm` file. Use the dependency installation and direct test commands above instead of relying on that build file.
