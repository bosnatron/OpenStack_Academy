import { Chessground } from 'https://esm.sh/@lichess-org/chessground@10.5.0';

const board = document.getElementById('academy-chessboard');
const overlay = document.getElementById('academy-welcome');
const dismiss = document.getElementById('academy-welcome-close');
const notice = document.getElementById('academy-board-status');

if (board && overlay && dismiss) {
  try {
    Chessground(board, {
      orientation: 'white',
      viewOnly: true,
      coordinates: true,
      animation: { enabled: true },
    });
    dismiss.addEventListener('click', () => {
      overlay.hidden = true;
      board.focus();
    });
  } catch (error) {
    if (notice) notice.textContent = 'The chessboard could not load. Please refresh the page.';
    console.error('Chessground initialization failed:', error);
  }
}
