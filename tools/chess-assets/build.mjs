// Run npm ci here first, then: node build.mjs /path/to/bosnatron-chessground
import { build } from 'esbuild';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '../..');
const revision = 'b4f605018e1043640c917e82a74b214cb58e4a05';
if (!process.argv[2]) throw new Error('Provide a clean checkout of bosnatron/chessground');
const fork = resolve(process.argv[2]);
const git = (...args) => execFileSync('git', ['-C', fork, ...args], { encoding: 'utf8' }).trim();
if (git('rev-parse', 'HEAD') !== revision || git('status', '--porcelain')) {
  throw new Error('Chessground checkout must be clean at the documented revision');
}
const cg = resolve(root, 'public/vendor/chessground');
const cj = resolve(root, 'public/vendor/chess.js');
mkdirSync(cg, { recursive: true });
mkdirSync(cj, { recursive: true });
await build({ entryPoints: [resolve(fork, 'src/chessground.ts')],
  outfile: resolve(cg, 'chessground.js'), bundle: true, format: 'esm',
  minify: true, legalComments: 'inline', target: 'es2020',
  banner: { js: '/*! Chessground 10.5.0; Lichess contributors; GPL-3.0-or-later. See LICENSE and SOURCE.tar.gz. */' } });
for (const name of ['chessground.base.css', 'chessground.brown.css', 'chessground.cburnett.css']) {
  copyFileSync(resolve(fork, 'assets', name), resolve(cg, name));
}
copyFileSync(resolve(fork, 'LICENSE'), resolve(cg, 'LICENSE'));
const source = execFileSync('git', ['-C', fork, 'archive', '--format=tar',
  '--prefix=chessground/', revision, 'src', 'assets', 'LICENSE', 'README.md',
  'package.json', 'tsconfig.json'], { maxBuffer: 4 * 1024 * 1024 });
writeFileSync(resolve(cg, 'SOURCE.tar.gz'), gzipSync(source));
const chessPackage = resolve(here, 'node_modules/chess.js');
await build({ entryPoints: [resolve(chessPackage, 'dist/esm/chess.js')],
  outfile: resolve(cj, 'chess.js'), bundle: true, format: 'esm', minify: true,
  legalComments: 'inline', target: 'es2020',
  banner: { js: '/*! chess.js 1.4.0; Jeff Hlywa and contributors; BSD-2-Clause. See LICENSE. */' } });
copyFileSync(resolve(chessPackage, 'LICENSE'), resolve(cj, 'LICENSE'));
const files = ['chessground/chessground.js', 'chessground/chessground.base.css',
  'chessground/chessground.brown.css', 'chessground/chessground.cburnett.css',
  'chessground/LICENSE', 'chessground/SOURCE.tar.gz', 'chess.js/chess.js', 'chess.js/LICENSE'];
const sha256 = Object.fromEntries(files.map(file => [file,
  createHash('sha256').update(readFileSync(resolve(root, 'public/vendor', file))).digest('hex')]));
writeFileSync(resolve(root, 'public/vendor/chess-assets.json'), JSON.stringify({
  chessground: { repository: 'https://github.com/bosnatron/chessground', revision, version: '10.5.0' },
  chessjs: { package: 'chess.js', version: '1.4.0', repository: 'https://github.com/jhlywa/chess.js' },
  build: { esbuild: '0.28.1', target: 'es2020' }, sha256,
}, null, 2) + '\n');
console.log('Built local chess assets with source, licenses and SHA-256 manifest.');
