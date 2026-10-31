# Academy visitor cookie and BV access

**Status:** standalone Perl cookie/SQLite helper and tests added on the Academy feature branch. Not yet connected to HTTP requests or Bright Vale.

Academy owns cookie creation, validation and renewal. BV may receive the **validated** anonymous visitor ID, creation/last-seen/expiry timestamps, and monitored activity through an explicit local Perl integration. BV must not issue browser cookies or read the browser's raw Cookie header.

`Academy::VisitorCookie->new(dbh => $dbh)` initializes a local SQLite registry; `identify(cookie_id => $id, at => $epoch)` validates against the registry, creates an ID when absent/invalid/expired and renews its expiry. `cookie_header(visitor_id => $id, secure => $is_https)` formats the header for Dancer2 to set. Default lifetime: 365 days, renewed on each visit. No automatic record deletion is implemented. The browser may still discard cookies, and expiration cannot be disabled.

IDs come from /dev/urandom, not Perl rand(). Use Perl rand() only for choosing an approved chess puzzle.

Before enabling: choose the on-disk SQLite path and permissions; add Dancer2 request/response integration, cookie parser and trusted HTTPS detection; ensure one Set-Cookie header without overriding Dancer2's session cookie; connect BV to the validated metadata; add integration tests, privacy disclosures and access controls. Do not expose the SQLite database to public clients. Avoid treating IP as a stable visitor identity.
