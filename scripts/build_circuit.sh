#!/bin/bash
set -e

CIRCUIT="ageCheck"
PTAU="zkeys/powersOfTau28_hez_final_12.ptau"

echo "→ Compiling circuit..."
circom circuits/$CIRCUIT.circom \
  --r1cs \
  --wasm \
  --sym \
  --output build/

echo "→ Circuit info:"
snarkjs r1cs info build/$CIRCUIT.r1cs

echo "→ Groth16 setup..."
snarkjs groth16 setup \
  build/$CIRCUIT.r1cs \
  $PTAU \
  zkeys/${CIRCUIT}_0000.zkey

echo "→ Contributing randomness (phase 2)..."
echo "random entropy here" | snarkjs zkey contribute \
  zkeys/${CIRCUIT}_0000.zkey \
  zkeys/${CIRCUIT}_final.zkey \
  --name="local dev contribution" -v

echo "→ Exporting verification key..."
snarkjs zkey export verificationkey \
  zkeys/${CIRCUIT}_final.zkey \
  zkeys/verification_key.json

echo "→ Exporting Solidity verifier..."
snarkjs zkey export solidityverifier \
  zkeys/${CIRCUIT}_final.zkey \
  contracts/Verifier.sol

echo "Done! Files created:"
echo "  build/ageCheck.r1cs        (constraint system)"
echo "  build/ageCheck_js/         (WASM prover)"
echo "  zkeys/ageCheck_final.zkey  (proving key)"
echo "  zkeys/verification_key.json (verification key)"
echo "  contracts/Verifier.sol     (on-chain verifier)"