// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVerifier {
    function verifyProof(
        uint[2] calldata pA,
        uint[2][2] calldata pB,
        uint[2] calldata pC,
        uint[2] calldata pubSignals
    ) external view returns (bool);
}

contract AgeGate {
    IVerifier public immutable verifier;
    uint256 public immutable requiredYear;

    mapping(address => bool) public verified;

    event AgeVerified(address indexed user);

    error ProofInvalid();
    error WrongYear();
    error AlreadyVerified();

    constructor(address _verifier, uint256 _currentYear) {
        verifier = IVerifier(_verifier);
        requiredYear = _currentYear;
    }

    function verify(
        uint[2] calldata pA,
        uint[2][2] calldata pB,
        uint[2] calldata pC
    ) external {
        if (verified[msg.sender]) revert AlreadyVerified();

        // pubSignals[0] = isAdult (must be 1)
        // pubSignals[1] = currentYear (must match our stored year)
        uint[2] memory pubSignals = [uint(1), requiredYear];

        if (!verifier.verifyProof(pA, pB, pC, pubSignals)) {
            revert ProofInvalid();
        }

        verified[msg.sender] = true;
        emit AgeVerified(msg.sender);
    }

    // Example gated function — only callable by verified adults
    modifier onlyAdult() {
        require(verified[msg.sender], "Age not verified");
        _;
    }

    function doAdultThing() external onlyAdult returns (string memory) {
        return "Access granted";
    }
}