const axios = require('axios');

class TimeService {
  constructor(url) {
    this.correction = 0;
    this.mainServerAddress = url ?? 'http://172.21.213.189:3001';
  }

  syncTime = async () => {
    try {
      const response = await axios.get(`${this.mainServerAddress}/api/time`);

      const unixEpoch = new Date(1970, 0, 1);
      const seconds = (Date.now() - unixEpoch.getTime()) / 1000;

      if (response.status !== 200) {
        throw new Error(
          `TimeService | syncTime | ERROR : status ${response.status} `
        );
      }

      const time = response.data.time;

      this.correction = (time ?? seconds * 2) - seconds;

      //console.log(new Date(time * 1000)); // Умножаем на 1000, чтобы конвертировать в миллисекунды
    } catch (error) {
      if (error.message) console.error(error.message);
    }
  };
}

const timeService = new TimeService();

module.exports = { timeService };