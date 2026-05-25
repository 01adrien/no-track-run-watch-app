const http = require('http');
const os = require('os');

const PORT = 3000;

const trainingData = {
    label: "Training",
    date: "2026-03-25",
    duration: 1506,
    distance: 4933,
    blocks: [
        {
            label: "Warm Up",
            fields: [
                { distance: 1500, pace: 2.78 },
                { duration: 150, pace: 3.33 }
            ]
        },
        {
            label: "Cardio",
            fields: [
                { distance: 400, pace: 4.17 },
                { duration: 72, pace: 5.56 },
                { distance: 400, pace: 4.17 },
                { duration: 72, pace: 5.56 }
            ]
        },
        {
            label: "Calm Down",
            fields: [
                { duration: 480, pace: 2.78 }
            ]
        }
    ]
};

function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const net of interfaces[name]) {
            if (net.family === 'IPv4' && !net.internal) {
                return net.address;
            }
        }
    }
    return '127.0.0.1';
}

http.createServer((req, res) => {
    if (req.url === '/training') {
        res.writeHead(200, {
            'Content-Type': 'text/plain',
            'Connection': 'close'
        });
        return res.end("OK");
    }

    res.writeHead(404);
    res.end();
}).listen(3000, '0.0.0.0');

/*
const ip = getLocalIP();

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on 0.0.0.0:${PORT}`);
    console.log(`http://${ip}:${PORT}/training`);
});
*/