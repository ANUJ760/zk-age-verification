pragma circom 2.0.0
include "../node_modules/circomlib/circuits/comparators.circom";

template AgeCheck() {

    // Private inputs: Known only to the PROVER
    signal input birthYear;
    signal input currentYear;

    // Public outputs: revealed to the VERIFIER
    signal output isAdult;

    // Compute the age
    signal age;
    age <== currentYear - birthYear;

    // Check age greater than 18 or not
    component gte = GreaterEqThan(8); // n: number of bits to represent the values.
    gte.in[0] <== age;
    gte.in[1] <== 18;

    // Get output
    isAdult <== gte.out; // 1 if [0] > [1], else 0.

    // Force isAdult to be 1
    // This makes the circuit ONLY produce valid proofs when age >= 18
    isAdult === 1;
}

component main {public [currentYear]} = AgeCheck();
