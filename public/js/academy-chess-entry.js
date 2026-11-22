// The welcome control must work even when chess code or puzzle data fails.
(() => {
  const dismiss = document.getElementById('academy-welcome-close');
  const overlay = document.getElementById('academy-welcome');
  const board = document.getElementById('academy-chessboard');
  const notice = document.getElementById('academy-board-status');
  if (!dismiss || !overlay || !board || !notice) return;

  dismiss.addEventListener('click', () => {
    overlay.hidden = true;
    board.focus();
  });

  import('/js/academy-chess.js?v=offline-1').catch(error => {
    notice.textContent = 'Unable to load the local chess files. Please refresh after restarting Academy.';
    console.error('Academy chess loading failed:', error);
  });
})();
