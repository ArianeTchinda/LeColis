// src/config/jwt.js
const jwt = require('jsonwebtoken');

const JWT_SECRET         = process.env.JWT_SECRET         || 'dev_secret';
const JWT_EXPIRES_IN     = process.env.JWT_EXPIRES_IN     || '15m';
const JWT_REFRESH_SECRET  = process.env.JWT_REFRESH_SECRET  || 'dev_refresh_secret';
const JWT_REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES_IN || '7d';

function signAccess(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

function signRefresh(payload) {
  return jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: JWT_REFRESH_EXPIRES });
}

function verifyAccess(token) {
  return jwt.verify(token, JWT_SECRET);
}

function verifyRefresh(token) {
  return jwt.verify(token, JWT_REFRESH_SECRET);
}

module.exports = { signAccess, signRefresh, verifyAccess, verifyRefresh };
