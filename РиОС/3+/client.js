const dgram = require('dgram');
const client = dgram.createSocket('udp4');

const CLIENT_PORT = 5560;
const DISPATCHER_PORT = 5556;
const DISPATCHER_HOST = '172.21.213.189';

client.on('message', message => {
    console.log(`Received time: ${message.toString()}`);
    client.close();
});

client.on('error', err => {
    console.log(`Client error:\n${err.stack}`);
    client.close();
});

client.on('listening', () => {
    const address = client.address();
    console.log(`Client is listening on ${address.address}:${address.port}`);
});

client.on('close', () => {
    console.log('Client socket closed');
    process.exit(0);
});

client.bind(CLIENT_PORT);

const message = JSON.stringify({
    type: 'time',
    clientPort: CLIENT_PORT
});
client.send(message, DISPATCHER_PORT, DISPATCHER_HOST, (err) => {
    if (err) {
        console.log(`Error sending request: ${err}`);
        client.close();
    } else {
        console.log(`Sent request: ${message} to ${DISPATCHER_HOST}:${DISPATCHER_PORT}`);
    }
});
