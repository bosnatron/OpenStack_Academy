// Academy entrance: three legal White moves, with automatic Black defense.
// Chessground is the UI; chess.js validates legal moves and checkmate.
import { Chessground } from 'https://esm.sh/@lichess-org/chessground@10.5.0';
import { Chess } from 'https://esm.sh/chess.js@1.4.0';

const PUZZLES = [{
  id: 'queen-sacrifice-001',
  fen: '8/8/8/2N5/8/2k1N3/Q3r2q/K7 w - - 0 1',
  line: ['a2c4', 'c3d2', 'c4c1', 'd2c1', 'c5b3'],
}];
async function loadPuzzles() {
  const response = await fetch('/data/mate-in-three.json');
  if (!response.ok) throw new Error('Puzzle catalog unavailable');
  const data = await response.json();
  const extra = [];
  for (const p of data.puzzles || []) {
    try {
      if (!Array.isArray(p.moves) || p.moves.length !== 6) continue;
      const verify = new Chess(p.fen);
      verify.move({from:p.moves[0].slice(0,2),to:p.moves[0].slice(2,4),promotion:p.moves[0][4] || 'q'});
      const start = verify.fen();
      for (const raw of p.moves.slice(1)) {
        verify.move({from:raw.slice(0,2),to:raw.slice(2,4),promotion:raw[4] || 'q'});
      }
      if (verify.isCheckmate() && verify.turn() === 'b') extra.push({id:p.id,fen:start,line:p.moves.slice(1)});
    } catch (_) { /* Reject invalid puzzle data */ }
  }
  return [...PUZZLES, ...extra];
}

const board = document.getElementById('academy-chessboard');
const overlay = document.getElementById('academy-welcome');
const dismiss = document.getElementById('academy-welcome-close');
const notice = document.getElementById('academy-board-status');

if (board && overlay && dismiss && notice) {
  try {
    const puzzles = await loadPuzzles();
    const puzzle = puzzles[Math.floor(Math.random() * puzzles.length)];
    const proof = new Chess(puzzle.fen);
    for (const uci of puzzle.line) {
      proof.move({ from: uci.slice(0, 2), to: uci.slice(2, 4), promotion: uci[4] || 'q' });
    }
    if (puzzle.line.length !== 5 || !proof.isCheckmate()) {
      throw new Error('Invalid puzzle solution: ' + puzzle.id);
    }

    let game = new Chess(puzzle.fen);
    let whiteMoves = 0;
    let played = [];
    let busy = false;
    let solved = false;
    let replyTimer;
    let resetTimer;
    const uciOf = m => m.from + m.to + (m.promotion || '');
    const show = message => { notice.textContent = message; };

    function destinations() {
      const result = new Map();
      if (busy || solved || game.turn() !== 'w') return result;
      for (const m of game.moves({ verbose: true })) {
        if (!result.has(m.from)) result.set(m.from, []);
        result.get(m.from).push(m.to);
      }
      return result;
    }

    function redraw(lastMove) {
      ground.set({
        fen: game.fen(),
        turnColor: game.turn() === 'w' ? 'white' : 'black',
        check: game.isCheck() ? (game.turn() === 'w' ? 'white' : 'black') : false,
        lastMove,
        movable: {
          free: false,
          color: !busy && !solved && game.turn() === 'w' ? 'white' : undefined,
          dests: destinations(),
        },
      });
    }

    function resetPuzzle(message = 'White to move. Checkmate in three moves. (Move 1 of 3)') {
      clearTimeout(replyTimer);
      clearTimeout(resetTimer);
      game = new Chess(puzzle.fen);
      whiteMoves = 0;
      played = [];
      busy = false;
      solved = false;
      redraw(undefined);
      show(message);
    }

    // Defensive lookahead for deviations from the published line.
    // This is a small local search, not a full Stockfish engine.
    // White maximizes the score; Black minimizes it.
    const values = { p: 100, n: 320, b: 330, r: 500, q: 900, k: 0 };
    function evaluate() {
      if (game.isCheckmate()) return game.turn() === 'b' ? 100000 : -100000;
      if (game.isDraw()) return 0;
      let score = 0;
      for (const row of game.board()) {
        for (const piece of row) {
          if (piece) score += (piece.color === 'w' ? 1 : -1) * values[piece.type];
        }
      }
      return score;
    }
    function search(depth, alpha, beta) {
      if (depth === 0 || game.isGameOver()) return evaluate();
      const maximizing = game.turn() === 'w';
      let best = maximizing ? -Infinity : Infinity;
      for (const move of game.moves({ verbose: true })) {
        game.move(move);
        const value = search(depth - 1, alpha, beta);
        game.undo();
        if (maximizing) {
          best = Math.max(best, value);
          alpha = Math.max(alpha, best);
        } else {
          best = Math.min(best, value);
          beta = Math.min(beta, best);
        }
        if (beta <= alpha) break;
      }
      return best;
    }
    function defensiveReply(candidates) {
      // On the intended line, preserve the verified puzzle's reply.
      const expected = played.every((m, i) => m === puzzle.line[i])
        ? puzzle.line[played.length] : null;
      const published = candidates.find(m => uciOf(m) === expected);
      if (published) return published;

      // Else choose the reply that minimizes White's chances.
      // Search 2 additional plies: White's next move and Black's response.
      let best = candidates[0], lowest = Infinity;
      for (const move of candidates) {
        game.move(move);
        const value = search(2, -Infinity, Infinity);
        game.undo();
        if (value < lowest) { lowest = value; best = move; }
      }
      return best;
    }

    function blackReply() {
      const candidates = game.moves({ verbose: true });
      if (!candidates.length) {
        resetPuzzle('No legal Black reply. Puzzle reset — try again.');
        return;
      }
      const selected = defensiveReply(candidates);
      const move = game.move(selected);
      played.push(uciOf(move));
      busy = false;
      redraw([move.from, move.to]);
      show('Your move ' + (whiteMoves + 1) + ' of 3. Find checkmate.');
    }

    function afterWhiteMove(from, to) {
      if (busy || solved) return;
      let move;
      try {
        move = game.move({ from, to, promotion: 'q' });
      } catch {
        redraw(undefined);
        show('Illegal move. Choose a highlighted legal destination.');
        return;
      }
      whiteMoves++;
      played.push(uciOf(move));
      busy = true;
      redraw([from, to]);

      if (whiteMoves === 3) {
        if (game.isCheckmate()) {
          solved = true;
          redraw([from, to]);
          show('CHECKMATE! Puzzle solved in three White moves.');
          window.dispatchEvent(new CustomEvent('academy:chess-solved', {
            detail: { puzzleId: puzzle.id, line: [...played] },
          }));
        } else {
          show('No checkmate on move three. Resetting the puzzle...');
          resetTimer = setTimeout(() => resetPuzzle('No checkmate in three. Try again.'), 1100);
        }
        return;
      }
      if (game.isGameOver()) {
        resetTimer = setTimeout(() => resetPuzzle('Game ended early. Try again.'), 900);
        return;
      }
      show('Black is choosing a defensive reply...');
      replyTimer = setTimeout(blackReply, 450);
    }

    const ground = Chessground(board, {
      fen: puzzle.fen,
      orientation: 'white',
      turnColor: 'white',
      viewOnly: false,
      coordinates: true,
      animation: { enabled: true },
      premovable: { enabled: false },
      movable: {
        free: false,
        color: 'white',
        dests: destinations(),
        showDests: true,
        events: { after: afterWhiteMove },
      },
    });

    // After server confirmation, replace the chess challenge with a centered
    // congratulations screen for three seconds, then open the Academy.
    window.addEventListener('academy:chess-solved', async (event) => {
      show('Checkmate! Verifying access...');
      try {
        const response = await fetch('/api/chess/unlock', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'same-origin',
          body: JSON.stringify(event.detail),
        });
        if (!response.ok) throw new Error('Unlock request rejected');
        const result = await response.json();
        if (!result.ok || !result.unlocked) throw new Error('Access not confirmed');

        const gate = document.querySelector('.academy-gate');
        if (gate) gate.hidden = true;
        const celebration = document.createElement('div');
        celebration.setAttribute('role', 'status');
        celebration.setAttribute('aria-live', 'polite');
        celebration.style.cssText = 'position:fixed;inset:0;z-index:9999;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px;background:#101d32;color:#fff;text-align:center;padding:24px;font-family:system-ui,sans-serif';
        const icon = document.createElement('div');
        icon.textContent = '✓';
        icon.style.cssText = 'font-size:64px;color:#9ee6b4;line-height:1';
        const heading = document.createElement('h1');
        heading.textContent = 'Congratulations!';
        heading.style.cssText = 'margin:0;font-size:clamp(30px,6vw,48px)';
        const subtitle = document.createElement('p');
        subtitle.textContent = 'Access Granted';
        subtitle.style.cssText = 'margin:0;color:#9ee6b4;font-size:clamp(24px,4vw,34px);font-weight:700';
        const welcome = document.createElement('p');
        welcome.textContent = 'Welcome to OpenStack Academy';
        welcome.style.cssText = 'margin:0;color:#cbd5e1;font-size:16px';
        celebration.append(icon, heading, subtitle, welcome);
        document.body.appendChild(celebration);
        setTimeout(() => window.location.replace('/'), 3000);
      } catch (error) {
        console.error('Academy unlock failed:', error);
        show('Checkmate confirmed, but access could not be granted. Please refresh and try again.');
      }
    });

    dismiss.addEventListener('click', () => {
      overlay.hidden = true;
      board.focus();
    });
    document.getElementById('academy-board-reset')
      ?.addEventListener('click', () => resetPuzzle());
    show('White to move. Checkmate in three moves. (Move 1 of 3)');
  } catch (error) {
    notice.textContent = 'Unable to start the chess challenge. Please refresh the page.';
    console.error('Academy chess challenge failed:', error);
  }
}
