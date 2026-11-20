(() => {
      const svg = document.getElementById('gearField');
      const NS = 'http://www.w3.org/2000/svg';
      const teeth = 16;
      const pitchRadius = 70;
      const outerRadius = 76;
      const rootRadius = 64;
      const step = pitchRadius * 2;
      const toothAngle = (2 * Math.PI) / teeth;

      const outline = [];
      for (let t = 0; t < teeth; t++) {
        const start = t * toothAngle;
        for (const [fraction, radius] of [
          [0.00, rootRadius], [0.16, rootRadius],
          [0.32, outerRadius], [0.68, outerRadius],
          [0.84, rootRadius]
        ]) {
          const angle = start + fraction * toothAngle;
          outline.push(`${(Math.cos(angle) * radius).toFixed(2)},${(Math.sin(angle) * radius).toFixed(2)}`);
        }
      }

      function element(tag, attributes) {
        const node = document.createElementNS(NS, tag);
        for (const [name, value] of Object.entries(attributes)) node.setAttribute(name, value);
        return node;
      }

      function draw() {
        const width = window.innerWidth;
        const height = window.innerHeight;
        svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
        svg.replaceChildren();
        const columns = Math.ceil(width / step) + 2;
        const rows = Math.ceil(height / step) + 2;

        for (let row = -1; row < rows; row++) {
          for (let column = -1; column < columns; column++) {
            const x = column * step + step / 2;
            const y = row * step + step / 2;
            const carrier = element('g', { transform: `translate(${x} ${y})` });
            const wheel = element('g', { class: `gear-wheel${(row + column) % 2 ? ' reverse' : ''}` });
            wheel.style.setProperty('--initial-angle', (row + column) % 2 ? '11.25deg' : '0deg');
            wheel.appendChild(element('polygon', { points: outline.join(' '), class: 'gear' }));
            wheel.appendChild(element('circle', { r: '24', class: 'gear-cutout' }));
            wheel.appendChild(element('circle', { r: '10', class: 'gear' }));
            carrier.appendChild(wheel);
            svg.appendChild(carrier);
          }
        }
      }

      let pending = false;
      window.addEventListener('resize', () => {
        if (pending) return;
        pending = true;
        requestAnimationFrame(() => { pending = false; draw(); });
      });
      window.addEventListener('pointermove', event => {
        document.documentElement.style.setProperty('--light-x', event.clientX + 'px');
        document.documentElement.style.setProperty('--light-y', event.clientY + 'px');
      }, { passive: true });
      // Magnify the footer credit only when the pointer is on its letters.
      const credit = document.querySelector('.site-footer .container');
      const lens = document.getElementById('creditMagnifier');
      const enlarged = document.getElementById('magnifiedCredit');
      enlarged.textContent = credit.textContent;
      const zoom = 2.6;
      const lensSize = 132;
      const radius = lensSize / 2;

      function moveMagnifier(event) {
        const rect = credit.getBoundingClientRect();
        const range = document.createRange();
        range.selectNodeContents(credit);
        const overLetters = [...range.getClientRects()].some(part =>
          event.clientX >= part.left && event.clientX <= part.right &&
          event.clientY >= part.top && event.clientY <= part.bottom
        );
        if (!overLetters || event.pointerType === 'touch') {
          lens.classList.remove('visible');
          return;
        }

        // Float above the pointer while sampling the exact footer position below it.
        const left = Math.max(4, Math.min(innerWidth - lensSize - 4, event.clientX - radius));
        const top = Math.max(4, event.clientY - lensSize - 24);
        lens.style.left = left + 'px';
        lens.style.top = top + 'px';
        enlarged.style.width = rect.width + 'px';
        enlarged.style.left = (radius - zoom * (event.clientX - rect.left)) + 'px';
        enlarged.style.top = (radius - zoom * (event.clientY - rect.top)) + 'px';
        enlarged.style.transform = 'scale(' + zoom + ')';
        lens.classList.add('visible');
      }

      window.addEventListener('pointermove', moveMagnifier, { passive: true });
      window.addEventListener('pointerleave', () => lens.classList.remove('visible'));
      window.addEventListener('blur', () => lens.classList.remove('visible'));
      draw();
    })();
