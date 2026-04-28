/**
 * Logger structuré pour l'application LeColis.
 * Remplaçable par Winston / Pino en production.
 */

const LEVELS = { DEBUG: 'DEBUG', INFO: 'INFO', WARN: 'WARN', ERROR: 'ERROR' };

const _format = (level, message) => {
  const timestamp = new Date().toISOString();
  return `[${level}] ${timestamp} — ${message}`;
};

const logger = {
  info:  (msg) => console.log(_format(LEVELS.INFO, msg)),
  warn:  (msg) => console.warn(_format(LEVELS.WARN, msg)),
  error: (msg) => console.error(_format(LEVELS.ERROR, msg)),
  debug: (msg) => {
    if (process.env.NODE_ENV === 'development') {
      console.debug(_format(LEVELS.DEBUG, msg));
    }
  },
};

module.exports = logger;
