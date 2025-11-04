const log = require('./logger.js');
const axios = require('axios');
const dotenv = require('dotenv');
dotenv.config({ path: process.argv[2] || '.env' });
const { dbService } = require('./DBService.js');

class ReplicateService {
  constructor(url) {
    this.correction = 0;
    this.mainServerAddress = url ?? 'http://172.21.213.189:3001';
    log.info(`ReplicateService initialized with central server: ${this.mainServerAddress}`);
  }

  fetchCentralBODIasync = async () => {
    try {
      log.info(`Fetching BODI data from central server: ${this.mainServerAddress} for SUB: ${process.env.SUB}`);

      const response = await axios.post(
        `${this.mainServerAddress}/api/replicate/${process.env.SUB}`,
        {},
        {
          timeout: 10000,
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );

      if (response.status !== 200) {
        throw new Error(`HTTP status ${response.status}`);
      }

      const newData = response.data;
      log.info(`Received ${newData ? newData.length : 0} records from central server`);

      if (newData && newData.length > 0) {
        const existingData = await dbService.getBODIasync();

        // Фильтруем новые данные
        const filteredData = newData.filter(({ IST, DATV_SET }) => {
          const newIST = String(IST);
          const newDATV_SET = new Date(DATV_SET).getTime();

          return !existingData.some((existingItem) => {
            const existingIST = String(existingItem.IST);
            const existingDATV_SET = new Date(existingItem.DATV_SET).getTime();
            return existingIST === newIST && existingDATV_SET === newDATV_SET;
          });
        });

        log.info(`Filtered to ${filteredData.length} new records`);

        if (filteredData.length > 0) {
          // Валидация данных
          const validatedData = filteredData.map((item) => {
            return {
              ...item,
              ZNC: Math.min(item.ZNC || 0, 1e308),
            };
          });

          // Группировка для BODK
          const groupedData = validatedData.reduce((groups, item) => {
            const key = `${item.IST}-${item.SUB}`;
            if (!groups[key]) {
              groups[key] = [];
            }
            groups[key].push(item);
            return groups;
          }, {});

          // Обновление BODK
          for (const [key, group] of Object.entries(groupedData)) {
            const [ist, sub] = key.split('-');
            await dbService.setBODKAsync({
              IST: ist,
              SUB: sub,
              KZAP: group.length,
              DATV_SET: new Date()
            });
          }

          // Вставка данных
          await dbService.setBODIasync(validatedData);
          log.info(`Successfully processed ${validatedData.length} new records`);
        } else {
          log.info('No new records to process (all duplicates)');
        }
      } else {
        log.info('No data received from central server');
      }

      log.info('fetchCentralBODIasync completed successfully');
    } catch (error) {
      log.error(`fetchCentralBODIasync failed: ${error.message}`);
    }
  };
}

const replicateService = new ReplicateService();

module.exports = { replicateService };