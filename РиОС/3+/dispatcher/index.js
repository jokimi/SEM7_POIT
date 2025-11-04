const dgram = require('dgram');
const fs = require('fs');
const path = require('path');
const server = dgram.createSocket('udp4');
const config = require('./../config');

const coordinatorFilePath = path.join(__dirname, '../coordinator.json');
let coordinator = null;
const clients = new Map();

server.on('error', (err) => {
    console.log(`Dispatcher error:\n${err.stack}`);
    server.close();
});

server.on('listening', () => {
    const address = server.address();
    console.log(`Dispatcher is listening on ${address.address}:${address.port}`);
});

server.on('message', (message, rinfo) => {
    const rawMessage = message.toString();
    console.log(`Dispatcher received: "${rawMessage}" from ${rinfo.address}:${rinfo.port}`);

    try {
        const request = JSON.parse(rawMessage);
        
        if (request.type === 'set-coordinator' && request.host && request.port) {
            coordinator = { host: request.host, port: request.port };
            console.log(`👑 New coordinator has been set via network: ${coordinator.host}:${coordinator.port}`);
        
        } else if (request.type === 'time') {
            console.log(`Got time request from client ${rinfo.address}:${rinfo.port}`);
            if (coordinator && coordinator.host && coordinator.port) {
                clients.set(`${coordinator.host}:${coordinator.port}`, { address: rinfo.address, port: rinfo.port });
                console.log(`Forwarding request to coordinator ${coordinator.host}:${coordinator.port}`);
                server.send(message, coordinator.port, coordinator.host);
            } else {
                console.log('No coordinator set, cannot forward request.');
            }
        }
    } catch (e) {
        const coordinatorId = `${rinfo.address}:${rinfo.port}`;
        if (coordinator && coordinatorId === `${coordinator.host}:${coordinator.port}`) {
            const clientInfo = clients.get(coordinatorId);
            if (clientInfo) {
                console.log(`Got response "${rawMessage}" from coordinator, forwarding to client ${clientInfo.address}:${clientInfo.port}`);
                server.send(message, clientInfo.port, clientInfo.address);
                clients.delete(coordinatorId);
            }
        }
    }
});

server.bind(config.dispatcher.port, config.dispatcher.host);
