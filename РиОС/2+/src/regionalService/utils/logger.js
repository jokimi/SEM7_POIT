const winston = require('winston');
const dotenv = require('dotenv').config({ path: process.argv[2] || '.env' });

// Создаем логгер с консольным выводом
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) => {
      return `[${timestamp}] ${level.toUpperCase()}: ${message}`;
    })
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    new winston.transports.File({
      filename: `RegionalServer${process.env.PORT || 'default'}.log`,
      format: winston.format.json()
    })
  ],
});

module.exports = logger;