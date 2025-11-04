const { Sequelize, DataTypes } = require('sequelize');
const path = require('path');

async function initN_TI() {
  // Создаем прямое подключение к SQLite
  const sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: path.join(__dirname, 'CentralDatabase.sqlite'),
    logging: console.log
  });

  try {
    await sequelize.authenticate();
    console.log('Connected to SQLite database');

    // Определяем модель N_TI
    const N_TI = sequelize.define('N_TI', {
      IST: { type: DataTypes.STRING(3), allowNull: false },
      TABL: { type: DataTypes.STRING(5), allowNull: false },
      POK: { type: DataTypes.STRING(4), allowNull: false },
      UT: { type: DataTypes.STRING(2), allowNull: false },
      SUB: { type: DataTypes.STRING(6), allowNull: false },
      OTN: { type: DataTypes.STRING(2), allowNull: false },
      OBJ: { type: DataTypes.STRING(16), allowNull: false },
      VID: { type: DataTypes.STRING(2), allowNull: false },
      PER: { type: DataTypes.STRING(2), allowNull: false },
      N_TI: { type: DataTypes.INTEGER, allowNull: false },
      SUB_R: { type: DataTypes.STRING(6), allowNull: false },
      NAME: { type: DataTypes.STRING(50), allowNull: false },
      ACT: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true }
    }, {
      tableName: 'N_TI',
      timestamps: false
    });

    // Синхронизируем модель с базой данных
    await sequelize.sync();
    console.log('N_TI table synchronized');

    // Очищаем таблицу
    await N_TI.destroy({ where: {}, truncate: true });
    console.log('N_TI table cleared');

    // Добавляем тестовые данные
    const ntiData = [
      // Для SUB 101
      { IST: '001', TABL: 'TAB01', POK: 'POK1', UT: 'UT', SUB: '101', OTN: 'OT', OBJ: 'OBJ001', VID: 'VI', PER: '01', N_TI: 1, SUB_R: '102', NAME: 'Object A', ACT: true },
      { IST: '002', TABL: 'TAB01', POK: 'POK2', UT: 'UT', SUB: '101', OTN: 'OT', OBJ: 'OBJ002', VID: 'VI', PER: '02', N_TI: 2, SUB_R: '102', NAME: 'Object B', ACT: true },

      // Для SUB 102
      { IST: '001', TABL: 'TAB01', POK: 'POK1', UT: 'UT', SUB: '102', OTN: 'OT', OBJ: 'OBJ001', VID: 'VI', PER: '01', N_TI: 3, SUB_R: '103', NAME: 'Object A', ACT: true },
      { IST: '002', TABL: 'TAB01', POK: 'POK2', UT: 'UT', SUB: '102', OTN: 'OT', OBJ: 'OBJ002', VID: 'VI', PER: '02', N_TI: 4, SUB_R: '103', NAME: 'Object B', ACT: true },

      // Для SUB 103
      { IST: '001', TABL: 'TAB01', POK: 'POK1', UT: 'UT', SUB: '103', OTN: 'OT', OBJ: 'OBJ001', VID: 'VI', PER: '01', N_TI: 5, SUB_R: '101', NAME: 'Object A', ACT: true },
      { IST: '002', TABL: 'TAB01', POK: 'POK2', UT: 'UT', SUB: '103', OTN: 'OT', OBJ: 'OBJ002', VID: 'VI', PER: '02', N_TI: 6, SUB_R: '101', NAME: 'Object B', ACT: true }
    ];

    // Вставляем данные
    for (const data of ntiData) {
      await N_TI.create(data);
    }

    console.log('N_TI data initialized successfully');

    // Проверяем добавленные данные
    const result = await N_TI.findAll();
    console.log(`Total N_TI records: ${result.length}`);

    console.log('\nAdded N_TI records:');
    result.forEach(record => {
      console.log(`- IST: ${record.IST}, SUB: ${record.SUB}, SUB_R: ${record.SUB_R}, NAME: ${record.NAME}`);
    });

  } catch (error) {
    console.error('Error initializing N_TI:', error);
  } finally {
    // Закрываем соединение
    if (sequelize) {
      await sequelize.close();
      console.log('Database connection closed');
    }
  }
}

// Запускаем инициализацию
initN_TI().then(() => {
  console.log('N_TI initialization completed successfully');
  process.exit(0);
}).catch(error => {
  console.error('N_TI initialization failed:', error);
  process.exit(1);
});