const { Sequelize, DataTypes } = require('sequelize');
const path = require('path');

class Database {
  constructor(ip, username, password, databaseName) {
    this.sequelize = new Sequelize({
      dialect: 'sqlite',
      storage: path.join(__dirname, '..', '..', `${databaseName}.sqlite`),
      logging: false,
    });

    // Определение таблицы BODI
    this.BODI = this.sequelize.define(
      'BODI',
      {
        IST: {
          type: DataTypes.STRING(3),
          allowNull: false,
          defaultValue: '-',
        },
        TABL: {
          type: DataTypes.STRING(5),
          allowNull: false,
          defaultValue: '-',
        },
        POK: {
          type: DataTypes.STRING(4),
          allowNull: false,
          defaultValue: '-',
        },
        UT: {
          type: DataTypes.STRING(2),
          allowNull: false,
          defaultValue: '00',
        },
        SUB: {
          type: DataTypes.STRING(6),
          allowNull: false,
          defaultValue: '-',
        },
        OTN: {
          type: DataTypes.STRING(2),
          allowNull: false,
          defaultValue: '00',
        },
        OBJ: {
          type: DataTypes.STRING(16),
          allowNull: false,
          defaultValue: '0000000000000000',
        },
        VID: {
          type: DataTypes.STRING(2),
          allowNull: false,
          defaultValue: '-',
        },
        PER: {
          type: DataTypes.STRING(2),
          allowNull: false,
          defaultValue: '-',
        },
        DATV: {
          type: DataTypes.DATE,
          allowNull: false,
          defaultValue: DataTypes.NOW,
        },
        DATV_SET: {
          type: DataTypes.DATE,
          allowNull: false,
          defaultValue: DataTypes.NOW,
        },
        ZNC: {
          type: DataTypes.FLOAT,
          allowNull: true,
        },
        PP: {
          type: DataTypes.STRING(2),
          allowNull: true,
          defaultValue: null,
        },
      },
      {
        tableName: 'BODI',
        timestamps: false,
      }
    );

    // Определение таблицы BODK
    this.BODK = this.sequelize.define(
      'BODK',
      {
        IST: {
          type: DataTypes.STRING(3),
          allowNull: false,
          defaultValue: '-',
        },
        SUB: {
          type: DataTypes.STRING(6),
          allowNull: false,
          defaultValue: '-',
        },
        DATV_SET: {
          type: DataTypes.DATE,
          allowNull: false,
          defaultValue: DataTypes.NOW,
        },
        KZAP: {
          type: DataTypes.INTEGER,
          allowNull: false,
          defaultValue: 0,
        },
      },
      {
        tableName: 'BODK',
        timestamps: false,
      }
    );

    // Определение таблицы N_TI
    this.N_TI = this.sequelize.define(
      'N_TI',
      {
        IST: {
          type: DataTypes.STRING(3),
          allowNull: false,
        },
        TABL: {
          type: DataTypes.STRING(5),
          allowNull: false,
        },
        POK: {
          type: DataTypes.STRING(4),
          allowNull: false,
        },
        UT: {
          type: DataTypes.STRING(2),
          allowNull: false,
        },
        SUB: {
          type: DataTypes.STRING(6),
          allowNull: false,
        },
        OTN: {
          type: DataTypes.STRING(2),
          allowNull: false,
        },
        OBJ: {
          type: DataTypes.STRING(16),
          allowNull: false,
        },
        VID: {
          type: DataTypes.STRING(2),
          allowNull: false,
        },
        PER: {
          type: DataTypes.STRING(2),
          allowNull: false,
        },
        N_TI: {
          type: DataTypes.INTEGER,
          allowNull: false,
          defaultValue: 0,
        },
        SUB_R: {
          type: DataTypes.STRING(6),
          allowNull: false,
        },
        NAME: {
          type: DataTypes.STRING(50),
          allowNull: false,
        },
        ACT: {
          type: DataTypes.BOOLEAN,
          allowNull: false,
          defaultValue: true,
        },
      },
      {
        tableName: 'N_TI',
        timestamps: false,
      }
    );

    // Определение таблицы T_SUB
    this.T_SUB = this.sequelize.define(
      'T_SUB',
      {
        ACT: {
          type: DataTypes.BOOLEAN,
          allowNull: false,
          defaultValue: true,
        },
        SUB: {
          type: DataTypes.STRING(6),
          allowNull: false,
        },
        SUB_NAME: {
          type: DataTypes.STRING(50),
          allowNull: false,
        },
        WITH_PROXY: {
          type: DataTypes.BOOLEAN,
          allowNull: false,
          defaultValue: false,
        },
        SUB_ADR: {
          type: DataTypes.STRING(50),
          allowNull: false,
        },
        SUB_PORT: {
          type: DataTypes.INTEGER,
          allowNull: false,
          defaultValue: 80,
        },
        SUB_PROXY: {
          type: DataTypes.STRING(60),
          allowNull: true,
        },
        SUB_PATH: {
          type: DataTypes.STRING(255),
          allowNull: false,
          defaultValue: '/api',
        },
        SUB_PROXY_PORT: {
          type: DataTypes.INTEGER,
          allowNull: true,
        },
      },
      {
        tableName: 'T_SUB',
        timestamps: false,
      }
    );

    // Инициализация таблиц
    this.initTables();
  }

  async initTables() {
    try {
      await this.sequelize.authenticate();
      await this.sequelize.sync(); // Создает таблицы если их нет

      // Добавляем тестовые данные в T_SUB
      const existingData = await this.T_SUB.findAll();
      if (existingData.length === 0) {
        await this.T_SUB.bulkCreate([
          {
            ACT: true,
            SUB: '101',
            SUB_NAME: 'Regional Service 1',
            SUB_ADR: '172.21.213.24',
            SUB_PORT: 4001,
            SUB_PATH: '/api'
          },
          {
            ACT: true,
            SUB: '102',
            SUB_NAME: 'Regional Service 2',
            SUB_ADR: '172.21.213.24',
            SUB_PORT: 4002,
            SUB_PATH: '/api'
          },
          {
            ACT: true,
            SUB: '103',
            SUB_NAME: 'Regional Service 3',
            SUB_ADR: '172.21.213.24',
            SUB_PORT: 4003,
            SUB_PATH: '/api'
          }
        ]);
      }
    } catch (error) {
      console.error('Error initializing database:', error);
    }
  }

  async connect() {
    return true;
  }

  async disconnect() {
    await this.sequelize.close();
  }

  async insertIntoBODI(data) {
    try {
      const result = await this.BODI.create(data);
      return result;
    } catch (error) {
      console.error('Error inserting into BODI:', error);
      throw error;
    }
  }

  async getFromBODI(query = {}) {
    try {
      const result = await this.BODI.findAll(query);
      return result;
    } catch (error) {
      console.error('Error fetching from BODI:', error);
      throw error;
    }
  }

  async insertIntoBODK(data) {
    try {
      const result = await this.BODK.create(data);
      return result;
    } catch (error) {
      console.error('Error inserting into BODK:', error);
      throw error;
    }
  }

  async getFromBODK(query = {}) {
    try {
      const result = await this.BODK.findAll(query);
      return result;
    } catch (error) {
      console.error('Error fetching from BODK:', error);
      throw error;
    }
  }

  async insertIntoN_TI(data) {
    try {
      const result = await this.N_TI.create(data);
      return result;
    } catch (error) {
      console.error('Error inserting into N_TI:', error);
      throw error;
    }
  }

  async getFromN_TI(query = {}) {
    try {
      const result = await this.N_TI.findAll(query);
      return result;
    } catch (error) {
      console.error('Error fetching from N_TI:', error);
      throw error;
    }
  }

  async insertIntoT_SUB(data) {
    try {
      const result = await this.T_SUB.create(data);
      return result;
    } catch (error) {
      console.error('Error inserting into T_SUB:', error);
      throw error;
    }
  }

  async getFromT_SUB(type) {
    try {
      let query = {};
      if (type === 'regional') {
        query = {
          where: {
            SUB: {
              [Sequelize.Op.gt]: '100' // SUB > 100 для региональных сервисов
            }
          }
        };
      }

      const result = await this.T_SUB.findAll(query);
      return result;
    } catch (error) {
      console.error('Error fetching from T_SUB:', error);
      throw error;
    }
  }

  async updateACT(sub, newACT) {
    try {
      const result = await this.T_SUB.update(
        { ACT: newACT },
        {
          where: { SUB: sub },
        }
      );
      return result;
    } catch (error) {
      console.error(`Error updating ACT for SUB: ${sub}`, error);
      throw error;
    }
  }
}

module.exports = {
  Database,
};