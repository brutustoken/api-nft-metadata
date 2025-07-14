const data = require('./base-metadata.json');

const express = require('express');
const app = express();
const path = require('path');

const BigNumber = require('bignumber.js');
let cors = require('cors');

require('dotenv').config();

app.use(cors());

const port = process.env.PORT || 8000;

const RUTA = "/v1/"


app.get("/", async (req, res) => {
    res.send({ "ok": true });
});

app.get('health', (req, res) => {
    res.send("OK");
});

app.get(RUTA, async (req, res) => {
    res.send({ "ok": true });
});

app.use(RUTA + 'static', express.static(path.join(__dirname, '..', 'public')));

app.get(RUTA + "lottery", async (req, res) => {

    let resutado = data;
    let { ticket } = req.query;

    if (ticket && parseInt(ticket) >= 0) {
        resutado.image = "https://nft-metadata.brutusservices.com/v1/static/lottery/img/" + parseInt(ticket) + ".gif"
        resutado.number = parseInt(ticket)
        resutado.attributes[0].value = parseInt(ticket)

    }

    res.send(resutado);


});

app.listen(port, () => console.log('Escuchando Puerto: http://localhost:' + port + RUTA));
