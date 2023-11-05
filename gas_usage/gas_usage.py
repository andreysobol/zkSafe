calls_without_proof = {
    1: 9402,
    2: 17081,
    3: 24767,
    4: 32454,
    5: 40147,
    6: 47842,
    7: 55543,
    8: 63248,
    9: 70965,
    10: 78678,
    11: 86404,
    12: 94137,
    13: 101877,
    14: 109627,
    15: 117385,
    16: 125154,
    17: 132945,
    18: 140725,
    19: 148528,
    20: 156343,
    21: 164171,
    22: 172012,
    23: 179867,
    24: 187736,
    25: 195640,
    26: 203523,
    27: 211441,
    28: 219375,
    29: 227327,
    30: 235297,
    31: 243286,
    32: 251294,
    33: 259351,
    34: 267371,
    35: 275441,
    36:	283533,
    37:	291646,
    38:	299782,
    39:	307944,
    40:	316128,
    41:	324376,
    42:	332571,
    43:	340830,
    44:	349116,
    45:	357429,
    46:	365769,
    47:	374139,
    48:	382536,
    49:	391017,
    50:	399421,
}

proof = 431777

eoa_erc_20_transfer = 41946
print("EOA ERC-20 transfer: " + str(eoa_erc_20_transfer))

safe_3_5_erc_20_transfer = 81452
print("Safe 3 of 5 ERC-20 transfer: " + str(safe_3_5_erc_20_transfer))

print("Multisig transfers from 1 to 50: ")

for i in range(1, 51):
    print(str((calls_without_proof[i] + proof) / i))