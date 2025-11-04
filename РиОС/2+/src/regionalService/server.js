const express = require('express');
const { timeService } = require('./utils/TimeService.js');
const { replicateService } = require('./utils/ReplicateService.js');
const router = require('./router.js');
const dotenv = require('dotenv');
const fs = require('fs');
const log = require('./utils/logger.js');

const envFile = process.argv[2] || '.env';

if (fs.existsSync(envFile)) {
  dotenv.config({ path: envFile });
  log.info(`Loaded environment from: ${envFile}`);
} else {
  log.error(`Configuration file ${envFile} not found.`);
  throw new Error(`Configuration file ${envFile} not found.`);
}

const PORT = process.env.PORT || 4000;
const app = express();

app.use(express.json());
app.use('/api', router(log));

// Endpoint для возврата BODI данных
app.get('/api/bodi', async (req, res) => {
  try {
    log.info('BODI endpoint called');

    const testData = [
      {
        IST: '001',
        TABL: 'TAB01',
        POK: 'POK1',
        UT: 'UT',
        SUB: process.env.SUB || '101',
        OTN: 'OT',
        OBJ: 'OBJ001',
        VID: 'VI',
        PER: '01',
        N_TI: 1,
        SUB_R: '102',
        NAME: 'Object A',
        ACT: 1,
        VALUE: 100.5
      },
      {
        IST: '002',
        TABL: 'TAB01',
        POK: 'POK2',
        UT: 'UT',
        SUB: process.env.SUB || '101',
        OTN: 'OT',
        OBJ: 'OBJ002',
        VID: 'VI',
        PER: '02',
        N_TI: 2,
        SUB_R: '102',
        NAME: 'Object B',
        ACT: 1,
        VALUE: 200.3
      }
    ];

    log.info(`Sending ${testData.length} test records from regional service on port ${PORT}`);

    res.json({
      success: true,
      data: testData,
      count: testData.length,
      service: `Regional Service ${PORT}`,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    log.error(`Error in /api/bodi: ${error.message}`);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  log.info('Health check called');
  res.json({
    status: 'healthy',
    service: 'Regional Service',
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

// Status endpoint для ping проверок
app.head('/api/status', (req, res) => {
  res.set('x-status', 'online');
  res.end();
});

app.listen(PORT, () => {
  log.info(`Региональный сервис запущен на порту: ${PORT}`);

  // Запускаем периодические задачи
  setInterval(() => {
    timeService.syncTime();
  }, 10000); // Каждые 10 секунд

  setInterval(() => {
    replicateService.fetchCentralBODIasync();
  }, 15000); // Каждые 15 секунд

  log.info('Periodic tasks scheduled');
});

//node .\src\regionalService\server.js t1.env