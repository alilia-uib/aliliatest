import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const port = process.env.PORT || 8080;
const root = path.join(import.meta.dirname, 'public');
const indexFile = path.join(root, 'index.html');

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript; charset=utf-8',
  '.mjs':  'application/javascript; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg':  'image/svg+xml',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif':  'image/gif',
  '.ico':  'image/x-icon',
  '.webp': 'image/webp',
  '.woff': 'font/woff',
  '.woff2':'font/woff2',
  '.ttf':  'font/ttf',
  '.map':  'application/json; charset=utf-8'
};

function send(res, filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const headers = { 'Content-Type': mime[ext] || 'application/octet-stream' };
  // Vite emits content-hashed files under /assets; everything else must revalidate.
  headers['Cache-Control'] = filePath.startsWith(path.join(root, 'assets') + path.sep)
    ? 'public, max-age=31536000, immutable'
    : 'no-cache';
  const stream = fs.createReadStream(filePath);
  stream.on('error', () => {
    if (!res.headersSent) res.writeHead(500);
    res.end();
  });
  res.writeHead(200, headers);
  stream.pipe(res);
}

const server = http.createServer((req, res) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, { Allow: 'GET, HEAD' }); res.end(); return;
  }

  let urlPath;
  try {
    urlPath = decodeURIComponent(req.url.split('?')[0]);
  } catch {
    res.writeHead(400); res.end('Bad Request'); return;
  }

  const filePath = path.join(root, urlPath === '/' ? 'index.html' : urlPath);
  if (filePath !== root && !filePath.startsWith(root + path.sep)) {
    res.writeHead(403); res.end('Forbidden'); return;
  }

  fs.stat(filePath, (err, stat) => {
    send(res, !err && stat.isFile() ? filePath : indexFile);
  });
});

// Bind explicitly to IPv4 so the App Service front end can reach the container.
server.listen(port, '0.0.0.0', () => console.log('Frontend listening on ' + port));
