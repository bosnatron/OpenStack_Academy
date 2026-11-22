# Local chess entrance

Academy serves the board JavaScript, rules library, styles, piece graphics,
puzzle catalog and penguin from its own HTTP server. A fresh browser can solve
the entrance and unlock lessons without contacting a CDN. The local Dancer2
server must still be running. External lesson links and externally hosted
instructional images are outside this offline chess feature.

The historical board initializer introduced in commit
`02dd41fd86c3e61a4a118b9f13b79d64d269692f` on 30 October 2026 imported Chessground
from esm.sh. The credits linked to the owner's fork, but that import did not
load the fork. This update replaces those runtime imports with local assets.

## Pinned assets and attribution

- Chessground 10.5.0 is built from **bosnatron/chessground**, revision
  `b4f605018e1043640c917e82a74b214cb58e4a05`. The three stylesheets are copied
  from that same revision; board and piece SVGs are embedded in the CSS.
  GPL-3.0-or-later text and corresponding TypeScript source are supplied as
  `/vendor/chessground/LICENSE` and `/vendor/chessground/SOURCE.tar.gz`.
- chess.js 1.4.0 is bundled from its pinned npm release. Its BSD-2-Clause
  license is supplied at `/vendor/chess.js/LICENSE`.
- `/vendor/chess-assets.json` records the upstream identity, build version and
  SHA-256 of each distributed asset. Credits remain on the chess and license pages.

No npm, Node, build step or internet download is needed to **run** the supplied
assets. `Chess::Rep` remains the installed Perl dependency for server-side
validation, as described in `chess-validation.md`.

## Independent welcome control

`academy-chess-entry.js` attaches the X handler before importing the chess code.
A missing library produces a visible error rather than disabling that control.
Missing puzzle data likewise leaves X usable. Neither failure unlocks lessons.
The server still validates the legal mating sequence; no client bypass was added.

## Rebuilding (maintainers only)

Obtain a clean checkout of the owner's Chessground fork at the revision above.
From Academy's root, with Node/npm available:

```sh
npm ci --prefix tools/chess-assets --ignore-scripts
node tools/chess-assets/build.mjs /path/to/bosnatron-chessground
```

The checked-in lockfile pins chess.js and esbuild 0.28.1. Installation requires
network access unless the build packages are already cached. The build refuses
a different or dirty Chessground revision. It regenerates bundles, styles,
licenses, source archive and checksums. Rebuilding a second time must leave
those asset hashes unchanged. Node modules are ignored and are not shipped.

## Verification

`prove -Ilib t` verifies server validation and byte-identical local asset delivery.
With Playwright/Chromium installed, run against a disposable Academy server:

```sh
python t/browser/chess_offline.py --base-url http://127.0.0.1:5102 --chromium /usr/bin/chromium
```

Four fresh contexts block all external requests without substituting libraries:
both rook finishes open lessons, X works with a missing library, and X works
with a failed catalog request. Failure cases leave the lesson gate locked.
Additional Chromium navigation checks cover 26 page states and 38 links at
desktop and phone widths, using only Academy-served chess assets.
