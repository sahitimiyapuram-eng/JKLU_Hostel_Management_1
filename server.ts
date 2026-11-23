import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
import { app } from './backend/src/app.js';
import { initDatabaseConnection } from './backend/src/config/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = parseInt(process.env.PORT || '3000', 10);
const isProduction = process.env.NODE_ENV === 'production';

async function startServer() {
  // Test/initialize MySQL connection pool
  await initDatabaseConnection();

  if (!isProduction) {
    // Mount Vite dev server middleware in development
    const { createServer } = await import('vite');
    const vite = await createServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    // In production, serve built frontend dist directory
    const express = (await import('express')).default;
    const distPath = path.resolve(__dirname, 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.resolve(distPath, 'index.html'));
    });
  }

const server = http.createServer(app);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[Hostel Management System] Server running on http://localhost:${PORT}`);
  console.log(`[Hostel Management System] REST APIs accessible at http://localhost:${PORT}/api/`);
});
}

startServer().catch((err) => {
  console.error('Fatal error starting server:', err);
  process.exit(1);
});
