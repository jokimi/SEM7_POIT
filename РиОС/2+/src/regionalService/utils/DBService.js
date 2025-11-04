const { Database } = require('../../database/DB');
const dotenv = require('dotenv');
dotenv.config({ path: process.argv[2] || '.env' });
const log = require('./logger.js');

class DBService {
  constructor(db) {
    this.db = db;
    this.db.connect().then(() => {
      log.info('Regional database connected successfully');
    }).catch(error => {
      log.error('Regional database connection failed:', error);
    });
  }

  setBODIasync = async (bodiData) => {
    try {
      log.info(`Setting ${bodiData.length} records into regional BODI`);

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
          DATV: new Date(),
          DATV_SET: data.DATV_SET || new Date(),
          ZNC: data.ZNC || data.KZAP || 0,
        };

        await this.db.insertIntoBODI(formattedData);
      }

      log.info(`Successfully set ${bodiData.length} records into regional BODI`);
      return bodiData.length;
    } catch (error) {
      log.error(`Error in setBODIasync: ${error.message}`);
      throw error;
    }
  };

  getBODIasync = async () => {
    try {
      const result = await this.db.getFromBODI();
      log.debug(`Retrieved ${result.length} records from regional BODI`);
      return result;
    } catch (error) {
      log.error(`Error in getBODIasync: ${error.message}`);
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

      log.info(`Inserting into regional BODK: ${JSON.stringify(formattedData)}`);
      await this.db.insertIntoBODK(formattedData);
      log.info('Successfully inserted record into regional BODK');

      return 1;
    } catch (error) {
      log.error(`Error in setBODKAsync: ${error.message}`);
      throw error;
    }
  };
}

const database = new Database(
  '172.21.213.189',
  'user',
  'password',
  process.env.DB_NAME
);

const dbService = new DBService(database);

module.exports = { dbService };