# Academy visitor collection and Academy_Agent

The collector belongs to OpenStack_Academy. Personal Bright Vale is not a
visitor service and its database is never a monitoring source.

Set `ACADEMY_VISITOR_DB` to a private local SQLite path before manually
launching `bin/app.psgi` through Plack. The middleware creates missing parent
directories with mode 0700 and new database files with mode 0600. Without the
variable, collection is off. Existing cookie and conversation databases are
not migrated, deleted or imported into a different application.

`Academy::VisitorCookie` validates a 64-hex random cookie against
`academy_visitor_cookies`, then renews its 365-day expiry. The HttpOnly,
SameSite=Lax cookie is Secure on HTTPS. Existing Dancer session cookies remain
separate. Trusted proxy configuration must establish `psgi.url_scheme`.

`Academy::VisitorActivity` appends request timestamps, sanitized paths, methods,
statuses, time until headers are ready and an HTML-GET page-view flag to
`academy_visitor_activity`. Its browser key is SHA256 of the validated cookie,
not the bearer-cookie value. Query strings, bodies and authorization headers
are excluded. Array responses, delayed responders and application exceptions
are recorded. A logging failure warns without replacing the website response.

Academy_Agent opens the configured source with SQLite read-only flags and
query_only, using a deferred read transaction. Its loopback dashboard is on
8084; it requires no model, chat history or personal BV services. It shows
24-hour request/page/browser/error counts, browsers observed in the last five
minutes, recent requests and path/browser summaries. A missing source or old
registry-only source is reported, never invented as live activity.

Cookie labels do not establish identity. These are HTTP observations, not a
record of every client action or exact time on page. Response-ready timing does
not include full streaming transfer or time spent reading. No automatic bans,
deletion, service launch or restart is enabled. Data remains local and ignored
by Git. Choose a retention/archive policy separately before sustained public use.

Smart_Chat is a construction placeholder only. Future requirements are in the
README and do not authorize implementing a chat backend in this change.
