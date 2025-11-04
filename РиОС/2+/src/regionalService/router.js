var express = require('express');
var router = express.Router();
const { dbService } = require('./utils/DBService.js');

router.head('/status', (req, res) => {
  res.set('x-status', 'online');
  res.end();
});

router.post('/replicate', async (req, res) => {
  const result = await dbService.getBODIasync();

  res.json(result);
});

module.exports = (logger) => {
  router.get('/endpoint', (req, res) => {
    logger.info('GET /endpoint was called');
    res.send('Hello World');
  });

  return router;
};