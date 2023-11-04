pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/eddsa.circom";
include "../node_modules/circomlib/circuits/pedersen.circom";

template SingleMultisig(ms, max) {

    // number 
    signal input n;
    signal input m;

    // signers
    signal input valid_signature[max];

    // message
    signal input msg[ms];

    // public key
    signal input A[max][256];

    // aggregated public key
    signal input public_key_hash[2];

    // signature
    signal input R8[max][256];
    signal input S[max][256];

    component pedersen = Pedersen(256*max + 2);

    pedersen.in[0] <== n;
    pedersen.in[1] <== m;

    for (var i=0; i<max; i++) {

        for (var j=0; j<256; j++) {
            pedersen.in[2 + i*256 + j] <== A[i][j];
        }

    }

    // aggregated public key result
    signal pedersen_hash[2];

    pedersen_hash[0] <== pedersen.out[0];
    pedersen_hash[1] <== pedersen.out[1];

    public_key_hash[0] === pedersen_hash[0];
    public_key_hash[1] === pedersen_hash[1];

    var amount_of_valid_signatures = 0;

    signal valid_signature_bool_validity[max];

    for (var i=0; i<max; i++) {
        valid_signature_bool_validity[i] <-- valid_signature[i] < 2 ? 1 : 0;
        valid_signature_bool_validity[i] === 1;

        amount_of_valid_signatures = amount_of_valid_signatures + valid_signature[i];
    }

    signal calculated_n <-- amount_of_valid_signatures;

    calculated_n === n;

    // first valid public key
    var first_valid_A_v[256];
    signal first_valid_A[256];

    // first valid public key
    var first_valid_R8_v[256];
    signal first_valid_R8[256];

    var first_valid_S_v[256];
    signal first_valid_S[256];

    for (var i=max-1; i>=0; i--) {
        for (var j=0; j<256; j++) {
            first_valid_A_v[j] = valid_signature[i] == 1 ? A[i][j] : first_valid_A_v[j];
            first_valid_R8_v[j] = valid_signature[i] == 1 ? R8[i][j] : first_valid_R8_v[j];
            first_valid_S_v[j] = valid_signature[i] == 1 ? S[i][j] : first_valid_S_v[j];
        }
    }

    for (var j=0; j<256; j++) {
        first_valid_A[j] <-- first_valid_A_v[j];
        first_valid_R8[j] <-- first_valid_R8_v[j];
        first_valid_S[j] <-- first_valid_S_v[j];
    }

    // final valid public key
    signal valid_A[max][256];

    // final valid signature
    signal valid_R8[max][256];
    signal valid_S[max][256];

    for (var i=max-1; i>=0; i--) {
        for (var j=0; j<256; j++) {
            valid_A[i][j] <-- valid_signature[i] == 1 ? A[i][j] : first_valid_A_v[j];
            valid_R8[i][j] <-- valid_signature[i] == 1 ? R8[i][j] : first_valid_R8_v[j];
            valid_S[i][j] <-- valid_signature[i] == 1 ? S[i][j] : first_valid_S_v[j];
        }
    }

    component sigs[max];

    for (var i=0; i<max; i++) {
        sigs[i] = EdDSAVerifier(ms);

        sigs[i].msg <== msg;

        sigs[i].A <== valid_A[i];
        sigs[i].R8 <== valid_R8[i];
        sigs[i].S <== valid_S[i];
    }
}

component main = SingleMultisig(80, 5);