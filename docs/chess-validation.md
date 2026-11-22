# Chess entrance validation

The browser previously verified checkmate using chess.js, but the Perl endpoint
compared the submitted sequence with one hardcoded solution. In puzzle
`mate-three-09tn6`, both `f1f8` and `e8f8` are mating finishes after
`d5f7 f8f7 e3e8 f7f8`. The second finish was rejected, leaving a solved visitor
outside the lessons.

`Academy::ChessChallenge` now uses [Chess::Rep](https://metacpan.org/pod/Chess::Rep)
0.8+ to replay each submitted move from a server-owned starting position. All
five plies must be legal; the fifth must leave the opponent in check with no
legal reply. Illegal moves, a mate/stalemate before the last move, non-mates,
unknown puzzle IDs and malformed requests do not create an unlocked session.
Promotion suffixes are explicitly restricted to pawns reaching the final rank.
The browser cannot supply the position or authorize itself with `checkmate:true`.

This accepts alternative legal mating sequences, not just the originally
recorded sequence. It does not prove that every preceding move forces mate
against every possible defense. The entrance remains a learning exercise,
not an authentication or anti-cheating system.

## One catalog

Both sides read `public/data/mate-in-three.json` (schema 2). Each puzzle has:

- A unique `id` and a valid starting `fen`.
- `setup_plies`: 1 for Lichess records whose first move is the opponent's setup
  move, or 0 when the FEN already shows the solver's starting position.
- `moves`: UCI coordinate moves containing that setup, if any, followed by one
  legal five-ply example solution.

The server validates example solutions at startup. The browser verifies them
too and uses the examples to guide its opponent. There is no second hardcoded
solution table to update when adding puzzles. Restart Academy after changing
the catalog, and reload the page to obtain the same catalog in the browser.
Retain the source and licensing information for added puzzles.

## Installation and verification

Install the `Chess::Rep` requirement using Academy's Perl before restarting;
the README includes the Mac command. It is declared in both `cpanfile` and
`Makefile.PL`. No Node process or external model is needed for server validation.

Run `prove -Ilib t` with Academy's dependencies available. The regression tests
replay all eight catalog solutions, verify that both rook finishes actually
open `/Step01` with the returned session cookie, and ensure rejected submissions
leave lessons locked. Tests use fresh sessions without a visitor database.

Chromium also completed both finishes through actual board clicks: `f1f8` at
desktop width and `e8f8` at phone width. Both displayed congratulations and
opened the lesson index. The browser check covered 26 page states and 38 lesson
navigation clicks. The latest cloud test blocks external requests and loads the real bundled
chess.js/Chessground packages and styles directly from Academy. See
[offline chess](offline-chess.md) for provenance and reproducible browser checks.
