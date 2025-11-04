const { Database } = require('../database/DB.js');

const SUB = [
  {
    db: new Database('172.21.213.24', 'user', 'pass', 'TerritorialDatabase1'),
    its: ['001', '002', '003'],
    sub: '101',
  },
  {
    db: new Database('172.21.213.24', 'user', 'pass', 'TerritorialDatabase2'),
    its: ['004', '005', '006'],
    sub: '102',
  },
  {
    db: new Database('172.21.213.24', 'user', 'pass', 'TerritorialDatabase3'),
    its: ['007', '008', '009'],
    sub: '103',
  },
];

setInterval(async () => {
  for (const sub of SUB) {
    await sub.db.connect();

    for (let i = 0; i < 1; i++) {
      // Изменили <= 3 на < sub.its.length
      let res = await sub.db.insertIntoBODI({
        IST: sub.its[i],
        TABL: `TAB01`,
        POK: `POK${i + 1}`,
        UT: '00',
        SUB: sub.sub,
        OTN: '00',
        OBJ: '0000000000000000',
        VID: '03',
        PER: '01',
        DATV: new Date(Date.now()).toISOString(),
        ZNC: 1,
        PP: '00',
      });

      let res2 = await sub.db.insertIntoBODK({
        IST: sub.its[i],
        SUB: sub.sub,
        DATV_SET: new Date(Date.now()).toISOString(),
        KZAP: 1,
      });
    }
    console.log(`generate data for ${sub.sub}`);
  }
}, 5000);