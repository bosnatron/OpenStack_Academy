# Academy persistent visitor cookie and BV monitoring boundary

**Status:** Perl/SQLite cookie helper, PSGI middleware and unit tests are on the feature branch. The middleware is **opt-in**; live BV monitoring is not connected.

Academy owns issuing, validating and renewing the browser's anonymous cookie. It does not deliberately delete cookie records. Browser storage and cookie expiration remain outside Academy's control. Default Max-Age is 365 days, renewed on each request.

To enable locally, configure ACADEMY_VISITOR_DB with an **existing writable private directory** and on-disk SQLite file path before starting the Academy PSGI app. Example: \`ACADEMY_VISITOR_DB=/private/path/academy-visitors.sqlite\`. Without that variable, the existing Academy behavior is preserved.

The middleware wraps \`Web->to_app\` in \`bin/app.psgi\`, validates the \`academy_visitor\` cookie against Academy's SQLite registry, refreshes the expiry and appends a Set-Cookie response header without overwriting Dancer2's session cookie. It adds the validated metadata to the private PSGI environment key \`academy.visitor\`, not to the public response. For HTTPS, \`Secure\` is set based on \`psgi.url_scheme\`; reverse proxies must set that trusted scheme correctly. Do not trust arbitrary client-supplied forwarded headers.

BV may receive the **validated** visitor ID and timestamps through an explicitly authorized local interface; it must not issue browser cookies, accept unvalidated client IDs or expose the SQLite file publicly. **The BV monitoring integration is still pending**. The browser identity is not proof of a unique human and may be lost when a browser clears its data.

Run: \`prove -Ilib -v t/visitor_cookie.t t/visitor_middleware.t\`. Full Dancer2 integration and live browser testing remain to be done. The chess entrance challenge and existing \`lib/Web.pm\` are unchanged.
