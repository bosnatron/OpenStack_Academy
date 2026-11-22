"""Run against a disposable Academy server with Playwright + Chromium installed.

python t/browser/chess_offline.py --base-url http://127.0.0.1:5102 --chromium /usr/bin/chromium
"""
import argparse
import json
from urllib.parse import urlsplit
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--base-url', required=True)
parser.add_argument('--chromium')
args = parser.parse_args()
base = args.base_url.rstrip('/')
origin = urlsplit(base).netloc
with sync_playwright() as pw:
    options = {'headless': True}
    if args.chromium:
        options['executable_path'] = args.chromium
    browser = pw.chromium.launch(**options)
    cases = []
    for finish, width in [('f1', 1440), ('e8', 390), ('missing_library', 390), ('missing_catalog', 390)]:
        context = browser.new_context(viewport={'width': width, 'height': 900}, service_workers='block')
        context.add_init_script("sessionStorage.setItem('academy-next-on-failure','mate-three-09tn6')")
        external = []
        def route(request):
            url = request.request.url
            if urlsplit(url).netloc != origin:
                external.append(url)
                return request.abort()
            if finish == 'missing_library' and '/vendor/chessground/chessground.js' in url:
                return request.abort()
            if finish == 'missing_catalog' and '/data/mate-in-three.json' in url:
                return request.fulfill(status=503, body='Unavailable')
            return request.continue_()
        context.route('**/*', route)
        page = context.new_page()
        page.goto(base, wait_until='domcontentloaded')
        # Click immediately; no need to wait for chess initialization.
        page.locator('#academy-welcome-close').click()
        assert page.locator('#academy-welcome').is_hidden()
        if finish.startswith('missing_'):
            page.wait_for_function("document.querySelector('#academy-board-status').textContent.includes('Unable')")
            assert context.request.get(base + '/Step01', max_redirects=0).status == 302
        else:
            page.wait_for_function("document.querySelector('#academy-board-status').textContent.includes('Attempt 1')")
            for source, target in [('d5', 'f7'), ('e3', 'e8'), (finish, 'f8')]:
                box = page.locator('cg-board').bounding_box()
                for square in (source, target):
                    page.mouse.click(box['x'] + (ord(square[0]) - ord('a') + .5) * box['width'] / 8,
                                     box['y'] + (8 - int(square[1]) + .5) * box['height'] / 8)
                if target != 'f8':
                    page.wait_for_timeout(750)
            page.wait_for_selector('#lessons-title', timeout=15000)
            assert not external, external
            page.locator('.lesson-next').click()
            page.wait_for_url(base + '/Step01')
        # Lesson 1 may contain external instructional images. The entrance
        # and unlocked index must have used only Academy resources.
        if finish.startswith('missing_'):
            assert not external, external
        else:
            assert not any('esm.sh' in u or 'jsdelivr.net' in u for u in external), external
        cases.append(finish)
        context.close()
    browser.close()
    print(json.dumps({'status': 'PASS', 'cases': cases, 'fresh_contexts': 4,
                      'external_network': 'blocked', 'library_fixtures': False}))
