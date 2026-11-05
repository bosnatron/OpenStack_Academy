(() => {
  'use strict';
  const button = document.getElementById('smart-chat-button');
  const notice = document.getElementById('smart-chat-notice');
  button?.addEventListener('click', () => {
    notice.hidden = false;
    button.setAttribute('aria-expanded', 'true');
  });
})();
