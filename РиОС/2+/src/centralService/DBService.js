const axios = require('axios');
const log = require('./logger.js');
const { Database } = require('../database/DB.js');
const dotenv = require('dotenv');
dotenv.config({ path: process.argv[2] || '.env' });
const { Op } = require('sequelize');

class DBService {
  constructor(db) {
    this.db = db;
    this.db.connect().then(() => {
      log.info('Database connected successfully');
    }).catch(error => {
      log.error('Database connection failed:', error);
    });
  }

  pingStatusServicesAsync = async () => {
    try {
      log.info('Starting pingStatusServicesAsync');
      const data = await this.db.getFromT_SUB('regional');

      if (data && data.length > 0) {
        log.info(`Found ${data.length} regional services to ping`);

        for (const elem of data) {
          try {
            const serviceUrl = `http://${elem.SUB_ADR}:${elem.SUB_PORT}`;
            log.info(`Pinging service: ${serviceUrl}`);

            let response;
            try {
              response = await axios.head(`${serviceUrl}/api/status`, { timeout: 5000 });
              log.info(`Response from ${serviceUrl}: ${response.status}`);
              await this.db.updateACT(elem.SUB, true);
            } catch (e) {
              log.error(`Request to ${serviceUrl} failed: ${e.message}`);
              await this.db.updateACT(elem.SUB, false);
            }
          } catch (error) {
            log.error(`Error processing service ${elem.SUB}: ${error.message}`);
          }
        }
      } else {
        log.warn('No regional services found in T_SUB table');
      }
    } catch (error) {
      log.error(`pingStatusServicesAsync error: ${error.message}`);
    }
  };

  getRegionalBODIAsync = async () => {
    try {
      log.info('Starting getRegionalBODIAsync');
      const services = await this.db.getFromT_SUB({
        where: {
          ACT: true
        }
      });

      if (!services || services.length === 0) {
        log.warn('No active services found for BODI data collection');
        return;
      }

      log.info(`Found ${services.length} active services`);

      for (const service of services) {
        try {
          const serviceUrl = `http://${service.SUB_ADR}:${service.SUB_PORT}/api/bodi`;
          log.info(`Fetching BODI data from: ${serviceUrl}`);

          const response = await axios.get(serviceUrl, { timeout: 10000 });

          if (response.data && response.data.success && response.data.data) {
            const newData = response.data.data;
            log.info(`Received ${newData.length} records from ${serviceUrl}`);

            if (newData.length > 0) {
              // Получаем существующие данные для проверки дубликатов
              const existingData = await this.getBODIAsync();

              // Улучшенная фильтрация дубликатов
              const filteredData = newData.filter(newItem => {
                return !existingData.some(existingItem =>
                  existingItem.IST === newItem.IST &&
                  existingItem.TABL === newItem.TABL &&
                  existingItem.POK === newItem.POK &&
                  existingItem.SUB === newItem.SUB &&
                  new Date(existingItem.DATV_SET).getTime() === new Date(newItem.DATV_SET).getTime()
                );
              });

              log.info(`After filtering: ${filteredData.length} new records`);

              if (filteredData.length > 0) {
                await this.setBODIAsync(filteredData);
                log.info(`Added ${filteredData.length} new records from ${serviceUrl}`);

                // Обновляем BODK
                const groupedData = filteredData.reduce((groups, item) => {
                  const key = `${item.IST}-${item.SUB}`;
                  if (!groups[key]) {
                    groups[key] = [];
                  }
                  groups[key].push(item);
                  return groups;
                }, {});

                for (const [key, group] of Object.entries(groupedData)) {
                  const [ist, sub] = key.split('-');
                  await this.setBODKAsync({
                    IST: ist,
                    SUB: sub,
                    KZAP: group.length,
                    DATV_SET: new Date()
                  });
                }
              } else {
                log.info(`No new records to add from ${serviceUrl} (all duplicates)`);
              }
            } else {
              log.info(`No data received from ${serviceUrl}`);
            }
          } else {
            log.warn(`Invalid response format from ${serviceUrl}: ${JSON.stringify(response.data)}`);
          }
        } catch (error) {
          log.error(`Error fetching from ${service.SUB_ADR}:${service.SUB_PORT}: ${error.message}`);
        }
      }
    } catch (error) {
      log.error(`getRegionalBODIAsync general error: ${error.message}`);
    }
  };

  getBODIAsync = async () => {
    try {
      const result = await this.db.getFromBODI();
      log.debug(`Retrieved ${result.length} records from BODI`);
      return result;
    } catch (error) {
      log.error(`Error in getBODIAsync: ${error.message}`);
      throw error;
    }
  };

  setBODIAsync = async (bodiData) => {
    try {
      log.info(`Inserting ${bodiData.length} records into BODI`);

      for (const data of bodiData) {
        const formattedData = {
          IST: data.IST,
          SUB: data.SUB,
          TABL: data.TABL,
          POK: data.POK,
          VID: data.VID,
          PER: data.PER,
          PP: data.PP,
          UT: data.UT,
          OTN: data.OTN,
          OBJ: data.OBJ,
          DATV_SET: data.DATV_SET || new Date(),
          ZNC: data.ZNC || data.VALUE || 0,
        };

        await this.db.insertIntoBODI(formattedData);
      }

      log.info(`Successfully inserted ${bodiData.length} records into BODI`);
      return bodiData.length;
    } catch (error) {
      log.error(`Error in setBODIAsync: ${error.message}`);
      throw error;
    }
  };

  getBODKAsync = async () => {
    try {
      const result = await this.db.getFromBODK();
      log.debug(`Retrieved ${result.length} records from BODK`);
      return result;
    } catch (error) {
      log.error(`Error in getBODKAsync: ${error.message}`);
      throw error;
    }
  };

  setBODKAsync = async (data) => {
    try {
      const formattedData = {
        IST: data.IST,
        SUB: data.SUB,
        DATV_SET: data.DATV_SET || new Date(),
        KZAP: data.KZAP,
      };

      log.info(`Inserting into BODK: ${JSON.stringify(formattedData)}`);
      await this.db.insertIntoBODK(formattedData);
      log.info('Successfully inserted record into BODK');

      return 1;
    } catch (error) {
      log.error(`Error in setBODKAsync: ${error.message}`);
      throw error;
    }
  };

  getN_TIasync = async (SUB_R) => {
    try {
      const result = await this.db.getFromN_TI({
        where: {
          SUB_R: SUB_R
        }
      });

      log.debug(`Retrieved ${result.length} records from N_TI for SUB_R: ${SUB_R}`);
      return result;
    } catch (error) {
      log.error(`Error in getN_TIasync: ${error.message}`);
      throw error;
    }
  };
}

// Создаем экземпляр базы данных для центрального сервиса
const database = new Database(
  '172.21.213.189',
  'user',
  'password',
  process.env.DB_NAME
);

const dbService = new DBService(database);

module.exports = {
  dbService,
};