# Publish on Render

This deployment runs the existing Perl/Dancer2 app using Starman in Docker.
It does not depend on the Codex cloud's `/workspace` directory or `.onboarding`
dependencies. No database or application credentials are needed.

## Publish

1. Make sure `Dockerfile`, `.dockerignore`, and `render.yaml` are committed and
   pushed to the GitHub branch you want to deploy. A file in the Codex cloud is
   not automatically on GitHub or on your own computer.
2. Sign in at https://render.com/ and connect your GitHub account. Do not share
   passwords or API keys in chat.
3. Create a Blueprint from `bosnatron/OpenStack_Academy`, select the branch with
   these files, and review `render.yaml`. Alternatively, create a Web Service,
   choose Docker as the runtime, use `./Dockerfile`, choose Free, and set the
   health check path to `/`.
4. Confirm the current plan is Free and review its current limits before
   deploying. Free-plan availability and account requirements are controlled
   by Render; this configuration does not guarantee eligibility.
5. Deploy. Render supplies the `PORT` variable and HTTPS. Use the actual
   `*.onrender.com` address shown in the dashboard; no particular name has been
   registered or reserved by these files. A custom domain is optional.

Automatic deploys are disabled in the Blueprint so publishing later commits
requires a deliberate manual deployment.

## Verify

The image build runs both existing test files. After deployment, visit `/` and
`/Step01` through `/Step09`, and verify `/css/style.css`,
`/js/academy-chess.js`, and `/data/mate-in-three.json` load successfully.
Test the interactive chess widget in a browser: it downloads JavaScript from
`esm.sh` and styles from `cdn.jsdelivr.net`. Local server tests do not validate
those remote browser dependencies.

Free services can have idle suspension, cold starts, resource limits, and
ephemeral filesystems. The app's file logs are not durable storage. Consult
https://render.com/docs/free for current terms. A separate `.com` or `.io`
domain is not included; the host-provided subdomain is enough to launch.

## Local Docker check

```sh
docker build -t openstack-academy .
docker run --rm -p 10000:10000 -e PORT=10000 openstack-academy
```

Check HTTP responses on port 10000. The service binds to `0.0.0.0` inside the
container and runs as an unprivileged user.
