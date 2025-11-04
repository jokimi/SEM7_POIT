const dgram = require('dgram');
const fs = require('fs');
const path = require('path');
const config = require('./../config');

const timeServiceHandlers = {
    "time": getTimeHandler,
    "ready": checkServerReady,
    "ready-ok": coordinatorIsReady,
    "init-coordinator": initCoordinator,
    "re-init-coordinator": reInitCoordinator,
    "who-is-coordinator": handleWhoIsCoordinator
};

const coordinatorFilePath = path.join(__dirname, '../coordinator.json');

const self = module.exports = {
    initTimeServer: ip => {
        const server = dgram.createSocket('udp4');
        server.ready = false;
        const timeServerConfig = config.timeService[ip];

        if (!timeServerConfig) {
            throw new Error(`No configuration found for IP: ${ip}`);
        }

        server.on('listening', () => {
            server.setBroadcast(true);
            const address = server.address();
            console.log(`Server-${ip} is listening to ${address.address}:${address.port}`);
        
            server.ready = true;
            
            const myIP = address.address;
            const allIPs = Object.keys(config.timeService).filter(k => /^\d{1,3}(\.\d{1,3}){3}$/.test(k));
            
            const maxIP = allIPs.sort((a, b) => {
                const numA = a.split('.').map(n => parseInt(n, 10));
                const numB = b.split('.').map(n => parseInt(n, 10));
                for (let i = 0; i < 4; i++) {
                    if (numA[i] !== numB[i]) return numB[i] - numA[i];
                }
                return 0;
            })[0];
            
            console.log(`My IP: ${myIP}, Max IP in config: ${maxIP}`);
            
            if (myIP === maxIP) {
                console.log(`🎯 I have the highest IP, becoming coordinator.`);
                // Announce immediately and then periodically.
                const announce = () => self.setCoordinator(myIP, address.port, server);
                setTimeout(announce, 500); // Initial announcement
                server.announcementInterval = setInterval(announce, 10000); // Repeat every 10 seconds
            } else {
                // If I am not the coordinator, I should actively look for one.
                const lookForCoordinator = () => {
                    const currentCoordinator = self.getCoordinator();
                    if (!currentCoordinator.host) {
                        console.log(`Server-${ip}: Still no coordinator. Sending out 'who-is-coordinator' message.`);
                        // Send to all other known services
                        const allServiceIPs = Object.keys(config.timeService).filter(k => /^\d{1,3}(\.\d{1,3}){3}$/.test(k) && k !== myIP);
                        allServiceIPs.forEach(serviceIp => {
                            server.send('who-is-coordinator', config.timeService.port, serviceIp);
                        });
                    } else {
                        // Once coordinator is found, stop looking.
                        if (server.lookForCoordinatorInterval) {
                            clearInterval(server.lookForCoordinatorInterval);
                            server.lookForCoordinatorInterval = null;
                        }
                    }
                };
                setTimeout(lookForCoordinator, 2000); // Start looking after 2 seconds
                server.lookForCoordinatorInterval = setInterval(lookForCoordinator, 10000); // Repeat every 10 seconds
            }
        });

        server.on('message', (message, client) => {
            const messageStr = message.toString();
            console.log(`Server-${ip} got: "${messageStr}" from ${client.address}:${client.port}`);
            
            let command = messageStr;
            try {
                const parsed = JSON.parse(messageStr);
                if (parsed.type) command = parsed.type;
            } catch (e) {}
            
            try {
                const handler = timeServiceHandlers[command];
                if (handler) handler(server, client);
            } catch (err) {
                console.log(`Error in handler for command "${command}": ${err}`);
            }
        });

        server.bind(config.timeService.port, timeServerConfig.host);
        setInterval(self.checkCoordinatorAvailable, config.timeService.checkCoordinatorInterval, server, ip);
        return server;
    },

    getCoordinator: () => {
        try {
            const data = fs.readFileSync(coordinatorFilePath).toString();
            return JSON.parse(data);
        } catch (err) {
            return { host: null, port: null };
        }
    },

    setCoordinator: (host, port, server) => {
        try {
            const coordinator = { host, port };
            fs.writeFileSync(coordinatorFilePath, JSON.stringify(coordinator, null, '  '));
            console.log(`Coordinator file written: ${host}:${port}`);

            if (server) {
                const dispatcherMessage = JSON.stringify({ type: 'set-coordinator', host, port });
                server.send(dispatcherMessage, config.dispatcher.port, config.dispatcher.host, (err) => {
                    if (err) console.log(`❌ Error sending info to dispatcher: ${err}`);
                    else console.log(`✅ Sent coordinator info to dispatcher at ${config.dispatcher.host}:${config.dispatcher.port}`);
                });

                const announcement = 'init-coordinator';
                const allServiceIPs = Object.keys(config.timeService).filter(k => /^\d{1,3}(\.\d{1,3}){3}$/.test(k));
                
                allServiceIPs.forEach(serviceIp => {
                    if (serviceIp !== host) {
                        server.send(announcement, config.timeService.port, serviceIp, (err) => {
                            if (err) console.log(`❌ Error announcing to service ${serviceIp}: ${err}`);
                            else console.log(`📢 Sent announcement to service ${serviceIp}`);
                        });
                    }
                });
            }
        } catch (err) {
            console.log(`Error in setCoordinator: ${err}`);
        }
    },
    
    checkCoordinatorAvailable: (server, ip) => {
        const coordinator = self.getCoordinator();
        if (!coordinator || !coordinator.host || !coordinator.port) {
            console.log(`Server-${ip}: No coordinator known. Waiting for election/update...`);
            return;
        }
        server.coordinatorReady = false;
        server.coordinator = { host: coordinator.host, port: coordinator.port };
        if (server.address().address !== server.coordinator.host) {
            console.log(`Server-${ip} checking coordinator availability on ${coordinator.host}:${coordinator.port}`);
            server.send('ready', server.coordinator.port, server.coordinator.host);
            self.recheckCoordinatorAvailable(server, ip, 1);
        }
    },

    recheckCoordinatorAvailable: (server, ip, attempt) => {
        setTimeout(() => {
            if (server.isElecting) return; // Prevent multiple elections at once

            if (!server.coordinatorReady && attempt < config.timeService.checkCoordinatorAttempts) {
                console.log(`Server-${ip} rechecking coordinator (Attempt ${attempt + 1})`);
                server.send('ready', server.coordinator.port, server.coordinator.host);
                self.recheckCoordinatorAvailable(server, ip, ++attempt);
            } else if (!server.coordinatorReady) {
                console.log(`Server-${ip} coordinator is NOT available. Starting new election.`);
                server.isElecting = true; // Set election flag

                const allServiceIPs = Object.keys(config.timeService).filter(k => /^\d{1,3}(\.\d{1,3}){3}$/.test(k));
                const myIpNum = ip.split('.').map(Number);

                const higherIPs = allServiceIPs.filter(otherIp => {
                    if (otherIp === ip) return false;
                    const otherIpNum = otherIp.split('.').map(Number);
                    for (let i = 0; i < 4; i++) {
                        if (otherIpNum[i] > myIpNum[i]) return true;
                        if (otherIpNum[i] < myIpNum[i]) return false;
                    }
                    return false;
                });

                if (higherIPs.length === 0) {
                    console.log(`Server-${ip}: No servers with higher IP. I am the new coordinator.`);
                    self.setCoordinator(ip, server.address().port, server);
                    server.isElecting = false;
                } else {
                    console.log(`Server-${ip}: Found servers with higher IP: ${higherIPs.join(', ')}. Sending 'election' message.`);
                    higherIPs.forEach(higherIp => {
                        server.send('election', config.timeService.port, higherIp);
                    });

                    // Wait for a response from a higher-up
                    let receivedResponse = false;
                    const electionTimeout = 2000; // 2 seconds

                    const onElectionResponse = (msg, rinfo) => {
                        if (msg.toString() === 'alive') {
                            console.log(`Received 'alive' from ${rinfo.address}. A higher-up will take over.`);
                            receivedResponse = true;
                            server.removeListener('message', onElectionResponse);
                            server.isElecting = false;
                        }
                    };
                    server.on('message', onElectionResponse);

                    setTimeout(() => {
                        server.removeListener('message', onElectionResponse);
                        if (!receivedResponse) {
                            console.log(`No response from higher-IP servers. I am the new coordinator.`);
                            self.setCoordinator(ip, server.address().port, server);
                        }
                        server.isElecting = false;
                    }, electionTimeout);
                }
            }
        }, 500);
    }
};

function getTimeHandler(server, client) {
    const coordinator = self.getCoordinator();
    const myAddress = server.address();
    if (server.ready && myAddress.address === coordinator.host) {
        const now = new Date();
        const day = String(now.getDate()).padStart(2, '0');
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const year = now.getFullYear();
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = String(now.getSeconds()).padStart(2, '0');
        const formattedTime = `${day}${month}${year}:${hours}:${minutes}:${seconds}`;
        console.log(`I am coordinator. Sending time "${formattedTime}" to ${client.address}:${client.port}`);
        server.send(formattedTime, client.port, client.address);
    }
}

function checkServerReady(server, client) {
    if (server.ready) {
        server.send('ready-ok', client.port, client.address);
    }
}

function coordinatorIsReady(server, client) {
    server.coordinatorReady = true;
}

function initCoordinator(server, client) {
    const myAddress = server.address().address;
    if (myAddress === client.address) return;
    console.log(`✅ Server-${myAddress} received 'init-coordinator' from ${client.address}.`);
    const currentCoordinator = self.getCoordinator();
    const clientIpParts = client.address.split('.').map(Number);
    const currentCoordinatorIpParts = currentCoordinator.host ? currentCoordinator.host.split('.').map(Number) : [0,0,0,0];
    let clientIsHigher = false;
    for (let i = 0; i < 4; i++) {
        if (clientIpParts[i] > currentCoordinatorIpParts[i]) { clientIsHigher = true; break; }
        if (clientIpParts[i] < currentCoordinatorIpParts[i]) break;
    }
    if (!currentCoordinator.host || clientIsHigher) {
        console.log(`Accepting ${client.address} as the new coordinator.`);
        self.setCoordinator(client.address, client.port, null);
        server.coordinatorReady = true;
        server.coordinator = { host: client.address, port: client.port };
    }
}

timeServiceHandlers['election'] = handleElection;

function handleElection(server, client) {
    // If I receive an election message, it means a lower-IP node is running for office.
    // I am alive, so I'll stop them and start my own election.
    console.log(`Received 'election' from ${client.address}. I am higher and alive.`);
    server.send('alive', client.port, client.address);
    // Start own election to become the coordinator
    const myAddress = server.address();
    self.setCoordinator(myAddress.address, myAddress.port, server);
}

function reInitCoordinator(server, client) {
    console.log(`Received re-init request from ${client.address}. I will run for coordinator.`);
    const myAddress = server.address();
    self.setCoordinator(myAddress.address, myAddress.port, server);
}

function handleWhoIsCoordinator(server, client) {
    const myAddress = server.address();
    const coordinator = self.getCoordinator();
    // If I am the coordinator, I should respond to the query.
    if (myAddress.address === coordinator.host) {
        console.log(`Received 'who-is-coordinator' from ${client.address}. Responding that I am the coordinator.`);
        self.setCoordinator(myAddress.address, myAddress.port, server); // Re-announce myself
    }
}