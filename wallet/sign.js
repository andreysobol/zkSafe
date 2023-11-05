const fs = require('fs');
const fsp = require('fs').promises;
const buildEddsa = require("circomlibjs").buildEddsa;
const buildPedersenHash = require("circomlibjs").buildPedersenHash;

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

function packOperation(amount, token, to) {
  // Create BigInt equivalents of the mask constants
  const mask253Bits = (BigInt(1) << BigInt(253)) - BigInt(1);
  const mask160Bits = (BigInt(1) << BigInt(160)) - BigInt(1);
  const mask66Bits = (BigInt(1) << BigInt(66)) - BigInt(1);

  // Prepare the packed array
  const packed = [BigInt(0), BigInt(0), BigInt(0)];

  // Parse the amount, token, and to as BigInt
  const amountBigInt = BigInt(amount);
  const tokenBigInt = BigInt(token);
  const toBigInt = BigInt(to);

  // Element 0: Just take the first 253 bits of the amount
  packed[0] = amountBigInt & mask253Bits;

  // Element 1: Last 3 bits of the amount, then the token, and finally the first 94 bits of 'to'
  const amountHigh3 = amountBigInt >> BigInt(253);
  const token160 = tokenBigInt & mask160Bits;
  const toHigh94 = toBigInt >> BigInt(66);
  packed[1] = (amountHigh3 << BigInt(253)) | (token160 << BigInt(93)) | toHigh94;

  // Element 2: The remaining 66 bits of 'to'
  const toLow66 = toBigInt & mask66Bits;
  packed[2] = toLow66;

  // Convert BigInts to binary strings for packed data
  return packed.map((n) => n.toString(2).padStart(256, '0')); // Padding each to 256 bits for consistent binary representation
}

function combineAndConvertToHex(packed) {
  // Combine the binary strings into one big binary string
  const combinedBinary = packed.join('');

  // Convert the combined binary string to a BigInt, then to a hexadecimal string
  const bigIntValue = BigInt('0b' + combinedBinary);
  const hexValue = bigIntValue.toString(16);

  return hexValue;
}

function replacer(key, value) {
  if (typeof value === 'bigint') {
    return value.toString();
  } else {
    return value;
  }
}

async function sign() {
  // multisig n/m
  const n = 3;
  const max_m = 5;
  const max_amount = 20;

  const amount = 10 ** 18;
  const token = BigInt('0xdac17f958d2ee523a2206206994597c13d831ec7');
  const to = BigInt('0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496');

  const packed = packOperation(amount, token, to);
  const hex = combineAndConvertToHex(packed);

  const eddsa = await buildEddsa();
  // const pedersen = await buildPedersenHash();
  // const b = Buffer.alloc(32);

  // const h = pedersen.hash(b);
  // const hP = babyJub.unpackPoint(h);


  let n_array = new Array(max_amount).fill(0);
  let m_array = new Array(max_amount).fill(0);
  n_array[0] = n;
  m_array[0] = max_m;

  let valid_signature = new Array(max_amount).fill(null).map((_, index) =>
        index === 0 ? [1, 1, 1, 0, 0] : new Array(max_m).fill(0)
    );

  let msg_array = new Array(max_amount).fill(null).map((_, index) =>
    index === 0 ? packed : new Array(packed.length).fill(0)
  );

  let signatures = [];
  const msg = Buffer.from(hex, "hex");
  const keysFilePath = 'keys.json';
  const keys = await importKeysFromJsonAsync(keysFilePath);

  for (let i = 0; i < max_m; i++) {
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

  const circuitInputs = {
    n: n_array,
    m: m_array,
    valid_signature: valid_signature,
    msg: msg_array
  };

  await fsp.writeFile('index.json', JSON.stringify(circuitInputs, replacer, 2));
}

sign()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });

