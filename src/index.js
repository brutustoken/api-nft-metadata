const data = require('./base-metadata.json');

const express = require('express');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const BigNumber = require('bignumber.js');
var cors = require('cors');

require('dotenv').config();

const app = express();
app.use(cors());

const port = process.env.PORT || 3012;

const URL = "/v1/"

app.get("",async(req,res) => {

    res.send({"ok":true});
});

app.get(URL,async(req,res) => {

    res.send({"ok":true});
});

app.get(URL+"lottery",async(req,res) => {

    if(req.query.ticket){
        var resutado = data;
        resutado.image = "https://nft.brutus.finance/lottery/img/"+parseInt(req.query.ticket)+".gif"
        resutado.number = parseInt(req.query.ticket)
        resutado.attributes[0].value = parseInt(req.query.ticket)

        
    }else{

        var resutado = data;
        resutado.image = "https://nft.brutus.finance/lottery/index.jpg"
        resutado.number = -1

    }

    res.send(resutado);

    
});

app.listen(port, ()=> console.log('Escuchando Puerto: http://localhost:' + port))
