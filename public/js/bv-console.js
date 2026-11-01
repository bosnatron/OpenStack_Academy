(() => {
  'use strict';
  const status = document.getElementById('bv-connection');
  const state = document.querySelector('.bv-state');
  const input = document.getElementById('bv-input');
  const send = document.getElementById('bv-send');
  const hint = document.getElementById('bv-hint');
  const log = document.getElementById('bv-messages');
  let connected = false;
  const copyAll = document.getElementById('bv-copy-all');
  copyAll?.addEventListener('click', async () => {
    const entries = [...log.querySelectorAll('.bv-message')].map(node =>
      (node.classList.contains('user') ? 'You: ' : 'Bright Vale: ') + node.textContent
    );
    const transcript = entries.join('\n\n');
    if (!transcript) { copyAll.textContent = 'No messages to copy'; return; }
    try {
      await navigator.clipboard.writeText(transcript);
      copyAll.textContent = 'Copied conversation';
    } catch (_) {
      const selection = window.getSelection();
      const range = document.createRange();
      range.selectNodeContents(log);
      selection.removeAllRanges();
      selection.addRange(range);
      copyAll.textContent = 'Select all prepared — press Cmd+C';
    }
  });
  function followLatest(messageNode) {
    requestAnimationFrame(() => {
      log.scrollTop = log.scrollHeight;
      messageNode.scrollIntoView({ behavior: 'smooth', block: 'end', inline: 'nearest' });
      requestAnimationFrame(() => { log.scrollTop = log.scrollHeight; });
    });
  }
  function add(role, message) {
    const p = document.createElement('div');
    p.className = 'bv-message ' + role;
    p.textContent = message;
    log.appendChild(p);
    followLatest(p);
  }
  async function check() {
    try {
      const r = await fetch('/api/bv/status', {credentials:'same-origin',cache:'no-store'});
      if (!r.ok) throw Error('Status unavailable');
      const data = await r.json();
      connected = data.connected === true;
      status.textContent = connected ? 'Local BV service connected' : 'Local BV service not connected';
      state.classList.toggle('connected', connected);
      input.disabled = !connected;
      send.disabled = !connected;
      hint.textContent = connected ? 'Messages go to the configured local BV service.' : 'No BV connection configured yet. The interface is ready.';
    } catch (_) {
      connected = false;
      status.textContent = 'Local BV connection unavailable';
      state.classList.remove('connected');
      input.disabled = true;
      send.disabled = true;
      hint.textContent = 'Check the Academy server and BV configuration.';
    }
  }
  document.getElementById('bv-form').addEventListener('submit', async e => {
    e.preventDefault();
    const message = input.value.trim();
    if (!connected || !message) return;
    input.value = '';
    input.disabled = true;
    send.disabled = true;
    add('user', message);
    try {
      const r = await fetch('/api/bv/message', {method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json'},body:JSON.stringify({message})});
      const data = await r.json();
      if (!r.ok || !data.ok) throw Error(data.error || 'BV did not respond');
      add('assistant', data.reply);
    } catch (error) {
      add('assistant', 'Unable to contact BV: ' + error.message);
    } finally { await check(); input.focus({ preventScroll: true }); }
  });
  check();
})();