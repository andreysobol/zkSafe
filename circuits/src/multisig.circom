pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/eddsa.circom";
include "../node_modules/circomlib/circuits/pedersen.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template SingleMultisig(ms, max_m) {

    // number 
    signal input n;
    signal input m;

    // signers
    signal input valid_signature[max_m];

    // message
    signal input msg[ms];

    // public key
    signal input A[max_m][256];

    // aggregated public key
    signal input public_key_hash[2];

    // signature
    signal input R8[max_m][256];
    signal input S[max_m][256];

    component pedersen = Pedersen(256*max_m + 2);

    pedersen.in[0] <== n;
    pedersen.in[1] <== m;

    for (var i=0; i<max_m; i++) {

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

    signal valid_signature_bool_validity[max_m];

    for (var i=0; i<max_m; i++) {
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

    for (var i=max_m-1; i>=0; i--) {
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
    signal valid_A[max_m][256];

    // final valid signature
    signal valid_R8[max_m][256];
    signal valid_S[max_m][256];

    for (var i=0; i<max_m; i++) {
        for (var j=0; j<256; j++) {
            valid_A[i][j] <-- valid_signature[i] == 1 ? A[i][j] : first_valid_A_v[j];
            valid_R8[i][j] <-- valid_signature[i] == 1 ? R8[i][j] : first_valid_R8_v[j];
            valid_S[i][j] <-- valid_signature[i] == 1 ? S[i][j] : first_valid_S_v[j];
        }
    }

    component sigs[max_m];

    for (var i=0; i<max_m; i++) {
        sigs[i] = EdDSAVerifier(ms);

        sigs[i].msg <== msg;

        sigs[i].A <== valid_A[i];
        sigs[i].R8 <== valid_R8[i];
        sigs[i].S <== valid_S[i];
    }
}

template packMessageToBits(ms, max_amount, serealized_message_size, bits_per_field) {
    // message
    signal input msg[max_amount][serealized_message_size];

    // message bits
    signal output msg_bits[max_amount][ms];

    component num2Bits[max_amount][serealized_message_size];

    for (var a=0; a<max_amount; a++) {
        for (var s=0; s<serealized_message_size; s++) {
            num2Bits[a][s] = Num2Bits(bits_per_field);
            num2Bits[a][s].in <== msg[a][s];
            for (var i=0; i<bits_per_field; i++) {
                if (s*bits_per_field + i < ms) {
                    num2Bits[a][s].out[i] ==> msg_bits[a][s*bits_per_field + i];
                }
            }
        }
    }
}

template AggregatedMultisig(ms, max_m, max_amount, serealized_message_size, bits_per_field) {

    // number 
    signal input n[max_amount];
    signal input m[max_amount];

    // signers
    signal input valid_signature[max_amount][max_m];

    // message
    signal input msg[max_amount][serealized_message_size];

    // public key
    signal input A[max_amount][max_m][256];

    // aggregated public key
    signal input public_key_hash[max_amount][2];

    // signature
    signal input R8[max_amount][max_m][256];
    signal input S[max_amount][max_m][256];

    signal input amount_to_prove;

    signal msg_bits[max_amount][ms];

    component pack = packMessageToBits(ms, max_amount, serealized_message_size, bits_per_field);
    msg ==> pack.msg;
    msg_bits <== pack.msg_bits;

    component multisig[max_amount];

    for(var a=0; a<max_amount; a++) {
        multisig[a] = SingleMultisig(ms, max_m);

        multisig[a].n <-- amount_to_prove > 0 ? n[a] : n[0];
        multisig[a].m <-- amount_to_prove > 0 ? m[a] : m[0];

        multisig[a].public_key_hash[0] <-- amount_to_prove > a ? public_key_hash[a][0] : public_key_hash[0][0];
        multisig[a].public_key_hash[1] <-- amount_to_prove > a ? public_key_hash[a][1] : public_key_hash[0][1];

        for (var i=0; i<ms; i++) {
            multisig[a].msg[i] <-- amount_to_prove > 0 ? msg_bits[a][i] : msg_bits[0][i];
        }

        for (var i=0; i<max_m; i++) {
            multisig[a].valid_signature[i] <-- amount_to_prove > a ? valid_signature[a][i] : valid_signature[0][i]; 

            for (var j=0; j<256; j++) {
                multisig[a].A[i][j] <-- amount_to_prove > a ? A[a][i][j] : A[0][i][j];
                multisig[a].R8[i][j] <-- amount_to_prove > a ? R8[a][i][j] : R8[0][i][j];
                multisig[a].S[i][j] <-- amount_to_prove > a ? S[a][i][j] : S[0][i][j];
            }
        }
    }
}

component main {public [public_key_hash, msg]} = AggregatedMultisig(576, 5, 20, 3, 253);