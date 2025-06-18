// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test, console} from "forge-std/Test.sol";
import {CertManager} from "@nitro-validator/CertManager.sol";

import "../src/NitroEnclavesManager.sol";

contract NitroEnclavesManagerTest is Test {
    NitroEnclavesManager nitroEnclavesManager;

    function setUp() public {
        vm.warp(1708930774);
        CertManager certManager = new CertManager();
        nitroEnclavesManager = new NitroEnclavesManager(certManager);
    }

    function test_validateAttestation() public {
        vm.startPrank(nitroEnclavesManager.owner());

        nitroEnclavesManager.registerPCR0(
            hex"17BF8F048519797BE90497001A7559A3D555395937117D76F8BAAEDF56CA6D97952DE79479BC0C76E5D176D20F663790"
        );

        bytes memory attestation = vm.readFileBinary("./test/nitro-attestation/sample_attestation.bin");
        (bytes memory attestationTbs, bytes memory signature) = nitroEnclavesManager.decodeAttestationTbs(attestation);
        nitroEnclavesManager.registerSigner(attestationTbs, signature);

        address expectedSigner = 0x874a4c5675cd4850dB08bD9A1e3184ED239087e4;
        assertTrue(nitroEnclavesManager.validSigners(expectedSigner));
    }
}
