#!/bin/bash

cd contracts/circuits

if [ -f ./powersOfTau28_hez_final_10.ptau ]; then
    echo "powersOfTau28_hez_final_10.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_10.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau
fi

echo "Compiling MastermindVariation.circom..."

# compile circuit

circom MastermindVariation.circom --r1cs --wasm --sym -o .
snarkjs r1cs info MastermindVariation.r1cs
circom bonus.circom --r1cs --wasm --sym -o .
snarkjs r1cs info bonus.r1cs

# Start a new zkey and make a contribution

snarkjs groth16 setup MastermindVariation.r1cs powersOfTau28_hez_final_10.ptau circuit_0000.zkey
snarkjs zkey contribute circuit_0000.zkey circuit_final.zkey --name="1st Contributor Name" -v -e="random text"
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json

snarkjs groth16 setup bonus.r1cs powersOfTau28_hez_final_10.ptau circuit_0000_bonus.zkey
snarkjs zkey contribute circuit_0000_bonus.zkey circuit_final_bonus.zkey --name="1st Contributor Name" -v -e="random text"
snarkjs zkey export verificationkey circuit_final_bonus.zkey verification_key_bonus.json

# generate solidity contract
snarkjs zkey export solidityverifier circuit_final.zkey ../verifier.sol
snarkjs zkey export solidityverifier circuit_final_bonus.zkey ../verifier_bonus.sol

cd ../..