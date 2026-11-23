
import app from '../backend/src/app.js';
import { initDatabaseConnection } from '../backend/src/config/db.js';

let dbReady: Promise<void> | null = null;

export default async function handler(req: any, res: any) {
  if (!dbReady) {
    dbReady = initDatabaseConnection();
  }

  await dbReady;
  return app(req, res);
}
