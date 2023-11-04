const crypto = require("crypto");
const buildEddsa = require("circomlibjs").buildEddsa;
const buildBabyjub = require("circomlibjs").buildBabyjub;

function buffer2bits(buff) {
    const res = [];
    for (let i=0; i<buff.length; i++) {
        for (let j=0; j<8; j++) {
            if ((buff[i]>>j)&1) {
                res.push(1n);
            } else {
                res.push(0n);
            }
        }
    }
    return res;
}

async function main() {
    let eddsa;
    let babyJub;

    eddsa = await buildEddsa();
    babyJub = await buildBabyjub();


    const msg = Buffer.from("00010203040506070809", "hex");
    const prvKey = Buffer.from("ca50ccdd166c67edc56dfe5fb5399156fa0d54f9fa4b83d9da6a5c61f978c34d", "hex");
    // const prvKey = crypto.randomBytes(32);
    const pubKey = eddsa.prv2pub(prvKey);
    const pPubKey = babyJub.packPoint(pubKey);


    const signature = eddsa.signPedersen(prvKey, msg);

    const pSignature = eddsa.packSignature(signature);
    const uSignature = eddsa.unpackSignature(pSignature);

    eddsa.verifyPedersen(msg, uSignature, pubKey);

    const msgBits = buffer2bits(msg);
    const r8Bits = buffer2bits(pSignature.slice(0, 32));
    const sBits = buffer2bits(pSignature.slice(32, 64));
    const aBits = buffer2bits(pPubKey);

    console.log("msg", msg);
    console.log("pubKey", pubKey);
    console.log("pPubKey", pPubKey);
    console.log("signature", signature);
    console.log("msgBits", msgBits);
    console.log("r8", r8Bits);
    console.log("s", sBits);
    console.log("a", aBits);
}

main()
    .then(() => {
    })
    .catch(err => {
        console.log(err);
        console.log("circuit err");
    });