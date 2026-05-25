const http = require('http');
const querystring = require('querystring');
const os = require('os');

const PORT = 3000;

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

function garminToJson(str) {
    try {
        const cleaned = str
            .replace(/=>/g, ':')
            .replace(/([a-zA-Z0-9_]+):/g, '"$1":');
        return JSON.parse(cleaned);
    } catch (e) {
        console.log("Erreur parsing Garmin:", e.message);
        return null;
    }
}

// =========================
// Serveur HTTP
// =========================
const server = http.createServer((req, res) => {

    if (req.method !== 'POST') {
        res.writeHead(405, { 'Content-Type': 'text/plain' });
        return res.end('Méthode non autorisée');
    }


    const clientIP = req.socket.remoteAddress; // 🔹 IP du client
    console.log(`Requête reçue de : ${clientIP}`);


    let body = '';
    req.on('data', chunk => body += chunk);

    req.on('end', () => {

        res.writeHead(200, { 'Content-Type': 'text/plain', 'Connection': 'close' });
        res.end('ok');

        setImmediate(() => {
            try {
                const parsed = querystring.parse(body);
                const sessionLabel = parsed.sessionLabel;
                const sessionDate = parsed.sessionDate;
                const rawResults = parsed.results ? decodeURIComponent(parsed.results) : null;
                const results = rawResults ? garminToJson(rawResults) : null;

                if (!sessionLabel || !sessionDate || !results) {
                    console.log("Données invalides reçues:", body);
                    return;
                }

                console.log("\nNouvelle session reçue");
                console.log("Label :", sessionLabel);
                console.log("Date  :", sessionDate);
                console.log("Résultats :", JSON.stringify(results, null, 2));

            } catch (e) {
                console.log("Erreur traitement données :", e.message);
            }
        });

    });

});

const ip = getLocalIP();
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on 0.0.0.0:${PORT}`);
    console.log(`Accessible sur le réseau local : http://${ip}:${PORT}`);
});