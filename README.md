# OpenStack_Academy

A local Dancer2 learning website with a chess entrance challenge and lessons.
The personal Bright Vale assistant is a separate project. Academy_Agent is a
separate, manually started visitor monitor; it is not a chat assistant.

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

## Smart_Chat — future work only

The homepage button after the chess puzzle displays **Under construction —
preview coming soon.** It makes no model request. The legacy `/bv` page also
shows a construction notice. No working visitor chat is included in this work.

Before implementing Smart_Chat in a future task:

1. Decide its Academy learning purpose and approve the chat scope separately.
2. Create independent visitor sessions and storage; never use personal BV memory or owner teaching.
3. Define access, consent, retention, rate limits and abuse handling for a visitor-facing service.
4. Give it a dedicated backend contract and model configuration; the browser must not call private BV or model ports.
5. Keep chat separate from the read-only monitoring dashboard and test that visitor messages cannot execute code or administrative actions.

Those items are plans, not implemented capabilities. Current work is visitor
monitoring and the construction placeholder only.

## Shared Academy appearance

The shared layout uses the black and green design from
`bosnatron.github.io/linux.html` (reference commit `3fdf699`). All nine lesson
pages use `public/css/style.css` and `public/js/terminal-theme.js`, including
the background gears and the same Slackware penguin fixed at the bottom left.
The penguin retains the reference page's Wikimedia image URL and needs network
access. Reduced-motion preferences disable gear rotation.

Lesson topic headings have one shared size (`--topic-size: 1.5rem`) and bold
weight (700). Change that variable to resize them together. The homepage chess
component keeps its original styling, puzzle data, and unlock behavior.
Lesson files are content fragments inside `views/layouts/main.tt`; avoid adding
page-wide styles or another HTML/head/body document inside a lesson.

Validation for this appearance update: the existing Perl suite passed
(6 files, 72 tests), and Chromium checked 13 pages at desktop and mobile widths
for consistent headings, a single main region, and horizontal overflow.
The cloud proxy blocked the external Wikimedia image, so its loading must be
checked in a browser with access to that host.
