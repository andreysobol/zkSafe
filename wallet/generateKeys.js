const crypto = require("crypto");
const fs = require("fs");
const buildEddsa = require("circomlibjs").buildEddsa;
const buildBabyjub = require("circomlibjs").buildBabyjub;


async function generateKeys() {
  let eddsa;
  let babyJub;
  let keys = [];

  eddsa = await buildEddsa();
  babyJub = await buildBabyjub();

  for (let i = 0; i < amount; i++) {
    const prvKey = crypto.randomBytes(32);
    const pubKey = eddsa.prv2pub(prvKey);
    const pPubKey = babyJub.packPoint(pubKey);

    keys.push({
      privateKey: prvKey.toString('hex'),
      publicKey: serializeUint8Arrays32ToHex(pubKey),
      packedPublicKey: uint8ArrayToHex(pPubKey)
    });
  }

  fs.writeFileSync('keys.json', JSON.stringify(keys, null, 2), 'utf-8');
  console.log("Keys:", keys);
  console.log(`${amount} keys have been generated and saved to keys.json`);
}

function serializeUint8Arrays32ToHex(input) {
  return input.map(uint8Array =>
    uint8ArrayToHex(uint8Array)
  ).join('');
}

function uint8ArrayToHex(input) {
  return Buffer.from(input).toString('hex');
}

const amount = process.argv[2] ? parseInt(process.argv[2], 10) : 1;

generateKeys(amount)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  })