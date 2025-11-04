var express = require('express');
const { dbService } = require('./DBService.js');
const log = require('./logger.js'); // ДОБАВЬТЕ ЭТУ СТРОКУ
var router = express.Router();

router.get('/', (req, res) => {
  res.json({ status: 'statusRouter' });
});

router.get('/time', (req, res) => {
  const unixEpoch = new Date(1970, 0, 1);
  const seconds = (Date.now() - unixEpoch.getTime()) / 1000;

  res.json({ time: seconds });
});

router.post('/replicate/:SUB', async (req, res) => {
  const { SUB } = req.params;
  log.info(`Replicate request for SUB: ${SUB}`);

  try {
    // Получаем все данные из таблицы BODI
    const data = await dbService.getBODIAsync();
    log.info(`Total BODI records: ${data.length}`);

    // Получаем строки из таблицы N_TI для заданного SUB
    const IST = await dbService.getN_TIasync(SUB);
    log.info(`Found ${IST ? IST.length : 0} IST records for SUB: ${SUB}`);

    // Проверяем, есть ли полученные значения IST
    if (!IST || IST.length === 0) {
      log.warn(`No IST records found for SUB: ${SUB}`);
      return res.status(200).json([]);
    }

    // Извлекаем массив значений IST из полученных данных
    const istValues = IST.map((item) => item.IST);
    log.info(`IST values to filter: ${istValues.join(', ')}`);

    // Фильтруем data, оставляя только записи, у которых IST есть в istValues
    const filteredData = data.filter((item) => istValues.includes(item.IST));
    log.info(`Filtered data count: ${filteredData.length}`);

    // Возвращаем отфильтрованные данные
    res.json(filteredData);
  } catch (error) {
    log.error(`Error in /replicate route for SUB ${SUB}: ${error.message}`);
    res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: error.message
    });
  }
});

module.exports = router;