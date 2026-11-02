# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

# Debian verifies package signatures; no CPAN bootstrap or local setup is needed.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates perl libdancer2-perl libtemplate-perl libyaml-perl \
       libplack-perl libhttp-message-perl starman \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 academy

WORKDIR /app
COPY --chown=academy:academy . .
ENV DANCER_ENVIRONMENT=production \
    DANCER_APPHANDLER=PSGI
RUN mkdir -p logs && chown academy:academy logs
USER academy
RUN prove -lr t

EXPOSE 10000
CMD ["sh", "-c", "exec starman --workers 2 --preload-app --listen 0.0.0.0:${PORT:-10000} bin/app.psgi"]
