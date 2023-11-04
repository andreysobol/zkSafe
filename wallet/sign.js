const fs = require('fs');
const fsp = require('fs').promises;
const buildEddsa = require("circomlibjs").buildEddsa;

async function importKeysFromJsonAsync(filePath) {
  try {
    const data = await fsp.readFile(filePath, 'utf8');
    const keys = JSON.parse(data);

    console.log('Keys imported successfully.');
    return keys;
  } catch (err) {
    console.error('Error reading keys from file:', err);
    throw err;
  }
}

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

async function sign(msg, amount) {
  let signatures = [];
  const eddsa = await buildEddsa();
  // const msg = Buffer.from("00010203040506070809", "hex");
  const msg = Buffer.from(msg, "hex");
  const keysFilePath = 'keys.json';
  const keys = await importKeysFromJsonAsync(keysFilePath);
  console.log(keys)

  for (let i = 0; i < amount; i++) {
    const privateKey = keys[i].privateKey;
    const publicKey = keys[i].publicKey;
    const packedPublicKey = keys[i].packedPublicKey;

    const signature = eddsa.signPedersen(privateKey, msg);
    const pSignature = eddsa.packSignature(signature);
    const uSignature = eddsa.unpackSignature(pSignature);

    eddsa.verifyPedersen(msg, uSignature, publicKey);

    const msgBits = buffer2bits(msg);
    const r8Bits = buffer2bits(pSignature.slice(0, 32));
    const sBits = buffer2bits(pSignature.slice(32, 64));
    const aBits = buffer2bits(packedPublicKey);

    signatures.push({
      msg: msg,
      pubKey: publicKey,
      pPubKey: packedPublicKey,
      signature: signature,
      msgBits: msgBits,
      r8: r8Bits,
      s: sBits,
      a: aBits
    });
  }

  fs.writeFileSync('signatures.json', JSON.stringify(signatures, null, 2), 'utf-8');
  console.log("Signatures:", signatures);
  console.log(`${amount} signatures have been generated and saved to signatures.json`);
}

sign(3)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

