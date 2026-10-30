import { Chessground } from 'https://esm.sh/@lichess-org/chessground@10.5.0';

const board = document.getElementById('academy-chessboard');
const overlay = document.getElementById('academy-welcome');
const dismiss = document.getElementById('academy-welcome-close');
const notice = document.getElementById('academy-board-status');

if (board && overlay && dismiss) {
  try {
    // Display all 32 pieces at their normal starting squares.
    // Free movement is for preview only; puzzle rules come in the next stage.
    const ground = Chessground(board, {
      fen: 'start',
      orientation: 'white',
      viewOnly: false,
      coordinates: true,
      animation: { enabled: true },
      movable: {
        free: true,
        color: 'both',
        showDests: false,
      },
    });

    dismiss.addEventListener('click', () => {
      overlay.hidden = true;
      board.focus();
    });

    // A convenient way to restore the pieces while testing the board.
    const reset = document.getElementById('academy-board-reset');
    reset?.addEventListener('click', () => {
      ground.set({ fen: 'start', lastMove: undefined, check: undefined });
    });

    if (notice) notice.textContent = 'Board preview: move pieces freely by dragging or clicking. Puzzle rules will be added next.';
  } catch (error) {
    if (notice) notice.textContent = 'The chessboard could not load. Please refresh the page.';
    console.error('Chessground initialization failed:', error);
  }
}
