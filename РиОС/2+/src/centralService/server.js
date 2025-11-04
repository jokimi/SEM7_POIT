const express = require('express');
const log = require('./logger.js');
const { dbService } = require('./DBService.js');
const statusRouter = require('./router.js');
const dotenv = require('dotenv');
const fs = require('fs');

const envFile = process.argv[2] || '.env';

if (fs.existsSync(envFile)) {
  dotenv.config({ path: envFile });
} else {
  throw new Error(`Файл конфигурации ${envFile} не найден.`);
}

const app = express();
const PORT = process.env.PORT || 3000;

app.use('/api', statusRouter);

app.listen(PORT, () => {
  log.info(`Центральный сервис запущен на порту: ${PORT}`);
  setInterval(dbService.pingStatusServicesAsync, 3000);
  setInterval(dbService.getRegionalBODIAsync, 5000);
});

//node .\src\centralService\server.js c1.env