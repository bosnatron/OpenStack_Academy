import { Chessground } from 'https://esm.sh/@lichess-org/chessground@10.5.0';
import { Chess } from 'https://esm.sh/chess.js@1.4.0';

const board = document.getElementById('academy-chessboard');
const overlay = document.getElementById('academy-welcome');
const dismiss = document.getElementById('academy-welcome-close');
const notice = document.getElementById('academy-board-status');
const reset = document.getElementById('academy-board-reset');

if (board && overlay && dismiss) {
  let ground;
  let game;
  let puzzle;
  let nextIndex = 1;
  let catalog = [];
  let cursor = -1;

  const say = message => { if (notice) notice.textContent = message; };
  const uci = move => move.from + move.to + (move.promotion || '');
  const squares = 'abcdefgh'.split('').flatMap(file =>
    '12345678'.split('').map(rank => file + rank));

  function showPosition() {
    const destinations = new Map();
    for (const square of squares) {
      const moves = game.moves({ square, verbose: true });
      if (moves.length) destinations.set(square, [...new Set(moves.map(move => move.to))]);
    }
    ground.set({
      fen: game.fen(),
      turnColor: game.turn() === 'w' ? 'white' : 'black',
      movable: { free: false, color: game.turn() === 'w' ? 'white' : 'black', dests: destinations },
      lastMove: undefined,
      check: game.isCheck(),
    });
  }

  function choosePuzzle(index) {
    if (!catalog.length) return;
    cursor = (index + catalog.length) % catalog.length;
    puzzle = catalog[cursor];
    game = new Chess(puzzle.fen);
    game.move({ from: puzzle.moves[0].slice(0,2), to: puzzle.moves[0].slice(2,4), promotion: puzzle.moves[0][4] });
    nextIndex = 1;
    showPosition();
    say('Checkmate in 3 moves · Puzzle ' + (cursor + 1) + ' of ' + catalog.length +
      ' · ' + (game.turn() === 'w' ? 'White' : 'Black') + ' to move.');
  }

  function handleMove(from, to, metadata) {
    if (!puzzle || nextIndex >= puzzle.moves.length) return;
    const expected = puzzle.moves[nextIndex];
    const proposed = from + to + (metadata?.promotion || '');
    if (proposed !== expected) {
      showPosition();
      say('Not the solution. Try another move — checkmate in 3.');
      return;
    }
    const played = game.move({ from, to, promotion: expected[4] });
    if (!played || uci(played) !== expected) {
      showPosition();
      say('Invalid move; position restored.');
      return;
    }
    nextIndex++;
    if (nextIndex === puzzle.moves.length) {
      showPosition();
      if (game.isCheckmate()) {
        ground.set({ movable: { color: undefined, dests: new Map() } });
        say('Checkmate! Puzzle solved. Reset to try another.');
      } else say('Puzzle validation failed; solution did not end in checkmate.');
      return;
    }
    const reply = puzzle.moves[nextIndex++];
    const result = game.move({ from: reply.slice(0,2), to: reply.slice(2,4), promotion: reply[4] });
    if (!result) {
      say('Puzzle data error. Reset to load another puzzle.');
      return;
    }
    showPosition();
    say('Correct! Find the next move (' + (Math.floor(nextIndex / 2) + 1) + ' of 3).');
  }

  // Reject malformed or incorrectly labelled puzzles before offering them.
  function validMateThree(candidate) {
    try {
      if (!Array.isArray(candidate.moves) || candidate.moves.length !== 6) return false;
      const verify = new Chess(candidate.fen);
      for (const raw of candidate.moves) {
        const move = verify.move({ from: raw.slice(0,2), to: raw.slice(2,4), promotion: raw[4] });
        if (!move || uci(move) !== raw) return false;
      }
      return verify.isCheckmate();
    } catch (_) { return false; }
  }

  try {
    ground = Chessground(board, {
      fen: 'start',
      orientation: 'white',
      coordinates: true,
      animation: { enabled: true },
      movable: { free: false, color: undefined, showDests: true, events: { after: handleMove } },
    });
    dismiss.addEventListener('click', () => {
      overlay.hidden = true;
      board.focus();
    });

    fetch('/data/mate-in-three.json', { cache: 'no-store' })
      .then(response => {
        if (!response.ok) throw new Error('Puzzle catalog unavailable');
        return response.json();
      })
      .then(data => {
        catalog = (data.puzzles || []).filter(validMateThree);
        if (!catalog.length) throw new Error('No validated mate-in-three puzzles');
        choosePuzzle(Math.floor(Math.random() * catalog.length));
      })
      .catch(error => {
        console.error('Academy puzzle catalog error:', error);
        say('Chessboard loaded, but the mate-in-three puzzles are unavailable.');
      });

    reset?.addEventListener('click', () => choosePuzzle(cursor + 1));
  } catch (error) {
    say('The chessboard could not load. Please refresh the page.');
    console.error('Chessground initialization failed:', error);
  }
}
