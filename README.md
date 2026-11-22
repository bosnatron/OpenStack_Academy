# Bosnatron Academy

A local Dancer2 learning website with a chess entrance challenge and lessons.
The personal Bright Vale assistant is a separate project. Academy_Agent is a
separate, manually started visitor monitor; it is not a chat assistant.

## Chess entrance validation

The server uses `Chess::Rep` 0.8+ to replay legal moves from the catalog's
starting position and check mate after three solver moves. Equivalent winning
lines are accepted, including either rook capturing on f8 in puzzle
`mate-three-09tn6`. The browser and server share one puzzle catalog; a browser
claim of checkmate alone cannot unlock lessons.

Install the additional dependency once with the Perl used to run Academy:

```sh
PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}" \
PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" \
/usr/bin/perl -MCPAN -e 'install "Chess::Rep"'
```

See [chess validation, tests and adding puzzles](docs/chess-validation.md).

## Run the website and collect visitor activity

Install the dependencies from `cpanfile` using your normal Perl environment.
Plack, DBI and DBD::SQLite must be available. From this repository:

```sh
ACADEMY_VISITOR_DB="$PWD/data_local/academy-visitors.sqlite" DANCER_APPHANDLER=PSGI plackup -s HTTP::Server::PSGI -Ilib --host 127.0.0.1 -p 5001 bin/app.psgi
```

The collector creates that separate private SQLite file and parent directory
when the website starts. `data_local/`, database files and backups are ignored
by Git. Use the same path for the monitoring agent. Do not point it at the
personal BV conversation database. Without `ACADEMY_VISITOR_DB`, collection is
disabled and the existing website still runs normally.

In another terminal, start the source copy in `Projects/Academy_Agent`:

```sh
perl /Users/BOSNATRON/Projects/Academy_Agent/bin_local/academy-agent.pl --project-root /Users/BOSNATRON/Projects/OpenStack_Academy
```

Open http://127.0.0.1:8084/ for the private monitoring dashboard. It reads the
website's database without modifying it and requires no chat model. Both
processes stop with Ctrl+C; no automatic startup or restart is installed.

## What is recorded

- Anonymous browser registrations, correlated using a hashed browser label.
- Requested paths, HTTP methods/statuses and timestamps, including chess-unlock requests.
- Time until response headers are ready, including delayed PSGI responses.
- Successful HTML GET page views, request counts, recent browsers and HTTP errors.

Query strings, request bodies, authorization headers and full visitor-cookie
values are not stored in activity events. Browser labels are not verified
people. HTTP requests do not reveal every click, typed text or exact time on a
page. Collection errors are reported in the website terminal; activity logging
failure does not replace a successful website response with an error. Events
are append-only; an explicit retention/archive policy can be chosen later.

The normal Plack entry point owns startup. Loading `Web.pm` does not itself
start another HTTP server. The collector and cookie registry remain Academy
modules, separate from the personal BV runtime.

## No chat or assistant connection

Academy is an educational website. It has no chat interface or assistant
connection. The former Smart_Chat placeholder, legacy chat page and unused API
routes have been removed. Academy_Agent remains a separate visitor monitor.

## Shared Academy appearance

The shared layout uses the black and green design from
`bosnatron.github.io/linux.html` (reference commit `3fdf699`). All nine lesson
pages use `public/css/style.css` and `public/js/terminal-theme.js`, including
the background gears and the same Slackware penguin fixed at the bottom left.
The Slackware penguin is served from `public/images/slackware-mascot.svg`,
including the welcome screen and chess entrance, so displaying it does not
require a request to Wikimedia. Source and licensing are recorded in
`docs/mascot-source.md`. Reduced-motion preferences disable gear rotation.

Lesson topic headings have one shared size (`--topic-size: 1.5rem`) and bold
weight (700). Change that variable to resize them together. The homepage chess
component keeps its original styling, puzzle data, and unlock behavior.
Lesson files are content fragments inside `views/layouts/main.tt`; avoid adding
page-wide styles or another HTML/head/body document inside a lesson.

Validation on 22 November 2026: the Perl suite passed (7 files, 119 tests),
including missing chat routes and local image delivery. Chromium checked 26
page states at desktop and phone widths, completed the chess challenge at both
widths, and followed all 38 forward/back lesson-navigation links. The penguin
loaded locally in every state without horizontal overflow. External requests
were blocked during this check; the real pinned chess libraries and styles
were supplied from a jsDelivr cache because the test environment blocks esm.sh.

Lesson navigation is rendered once by the shared layout, after the complete
lesson: Previous at the left and Next at the right. The unlocked lesson index
has Next to start Step01; Step09 finishes at the index. The locked chess
entrance has no back arrow or lesson navigation.

The displayed site name is **Bosnatron Academy**. The repository and local
folder remain `OpenStack_Academy`, so existing paths and launch commands work.

The footer links to `/license.html`, documenting the existing `perl` license
declaration in `Makefile.PL`, Chessground's GPL-3.0-or-later license, and the
penguin's source. Third-party credits remain intact.
