import { ethers } from "hardhat";
import { expect } from "chai";
import * as snarkjs from "snarkjs";
import * as fs from "fs";
import * as path from "path";

const CURRENT_YEAR = 2024;

async function generateProof(birthYear: number) {
  const input = { birthYear, currentYear: CURRENT_YEAR };

  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    input,
    "build/ageCheck_js/ageCheck.wasm",
    "zkeys/ageCheck_final.zkey"
  );

  // Convert proof to Solidity calldata format
  const calldata = await snarkjs.groth16.exportSolidityCallData(
    proof,
    publicSignals
  );

  // Parse the calldata string into arrays
  const argv = calldata
    .replace(/["[\]\s]/g, "")
    .split(",")
    .map((x: string) => BigInt(x));

  const pA = [argv[0], argv[1]];
  const pB = [
    [argv[2], argv[3]],
    [argv[4], argv[5]],
  ];
  const pC = [argv[6], argv[7]];

  return { pA, pB, pC };
}

describe("AgeGate", function () {
  let verifier: any;
  let ageGate: any;

  beforeEach(async function () {
    const Verifier = await ethers.getContractFactory("Groth16Verifier");
    verifier = await Verifier.deploy();

    const AgeGate = await ethers.getContractFactory("AgeGate");
    ageGate = await AgeGate.deploy(
      await verifier.getAddress(),
      CURRENT_YEAR
    );
  });

  it("accepts valid proof for adult (born 1995)", async function () {
    const { pA, pB, pC } = await generateProof(1995);
    await expect(ageGate.verify(pA, pB, pC)).to.emit(ageGate, "AgeVerified");
  });

  it("allows verified user to call gated function", async function () {
    const { pA, pB, pC } = await generateProof(1995);
    await ageGate.verify(pA, pB, pC);
    expect(await ageGate.doAdultThing()).to.equal("Access granted");
  });

  it("rejects double verification", async function () {
    const { pA, pB, pC } = await generateProof(1995);
    await ageGate.verify(pA, pB, pC);
    await expect(ageGate.verify(pA, pB, pC)).to.be.revertedWithCustomError(
      ageGate,
      "AlreadyVerified"
    );
  });

  // Note: testing the under-18 case is harder — the circuit itself
  // throws during witness generation, so you can't even get a proof.
  // That's the point.
});