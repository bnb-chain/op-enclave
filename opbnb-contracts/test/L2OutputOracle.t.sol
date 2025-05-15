// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test, console} from "forge-std/Test.sol";
import {ICertManager} from "@nitro-validator/ICertManager.sol";
import {ProxyAdmin} from "@opbnb-bedrock/src/universal/ProxyAdmin.sol";

import "../src/ResolvingProxyFactory.sol";
import "../src/NitroEnclavesManager.sol";
import "../src/SystemConfigOwnable.sol";
import "../src/L2OutputOracle.sol";

contract L2OutputOracleTest is Test {
    L2OutputOracle internal l2OutputOracle;

    function setUp() public {
        ProxyAdmin admin = new ProxyAdmin(address(this));
        NitroEnclavesManager scgImpl = new NitroEnclavesManager(ICertManager(address(0)));
        NitroEnclavesManager scg =
            NitroEnclavesManager(ResolvingProxyFactory.setupProxy(address(scgImpl), address(admin), 0x00));
        scg.initialize({_owner: address(this), _manager: address(this)});
        scg.setProposer(address(this));
        L2OutputOracle outputOracleImpl = new L2OutputOracle({_systemConfigGlobal: scg, _maxOutputCount: 6});
        l2OutputOracle = L2OutputOracle(ResolvingProxyFactory.setupProxy(address(outputOracleImpl), address(admin), 0x00));
        l2OutputOracle.initialize({
            _systemConfig: SystemConfigOwnable(address(0)),
            _configHash: bytes32(0),
            _genesisOutputRoot: bytes32(0),
            _proofsEnabled: false
        });
    }

    function test_getL2OutputIndexAfter() public {
        // only genesis proposed
        assertEq(outputOracle.getL2OutputIndexAfter(0), 0);
        vm.expectRevert(bytes("L2OutputOracle: cannot get output for a block that has not been proposed"));
        outputOracle.getL2OutputIndexAfter(1);

        // propose block 100 (index 1)
        outputOracle.proposeL2Output(bytes32(uint256(1)), 100, 0, "");
        assertEq(outputOracle.getL2OutputIndexAfter(0), 0);
        assertEq(outputOracle.getL2OutputIndexAfter(1), 1);
        assertEq(outputOracle.getL2OutputIndexAfter(100), 1);
        vm.expectRevert(bytes("L2OutputOracle: cannot get output for a block that has not been proposed"));
        outputOracle.getL2OutputIndexAfter(101);

        // propose block 200 (index 2)
        outputOracle.proposeL2Output(bytes32(uint256(2)), 200, 0, "");
        assertEq(outputOracle.getL2OutputIndexAfter(0), 0);
        assertEq(outputOracle.getL2OutputIndexAfter(1), 1);
        assertEq(outputOracle.getL2OutputIndexAfter(100), 1);
        assertEq(outputOracle.getL2OutputIndexAfter(101), 2);
        assertEq(outputOracle.getL2OutputIndexAfter(200), 2);
        vm.expectRevert(bytes("L2OutputOracle: cannot get output for a block that has not been proposed"));
        outputOracle.getL2OutputIndexAfter(201);

        // propose blocks 300 (3), 400 (4), 500 (5), 600 (0), 700 (1), 800 (2)
        outputOracle.proposeL2Output(bytes32(uint256(3)), 300, 0, "");
        outputOracle.proposeL2Output(bytes32(uint256(4)), 400, 0, "");
        outputOracle.proposeL2Output(bytes32(uint256(5)), 500, 0, "");
        outputOracle.proposeL2Output(bytes32(uint256(6)), 600, 0, "");
        outputOracle.proposeL2Output(bytes32(uint256(7)), 700, 0, "");
        outputOracle.proposeL2Output(bytes32(uint256(7)), 800, 0, "");
        assertEq(outputOracle.getL2OutputIndexAfter(0), 3);
        assertEq(outputOracle.getL2OutputIndexAfter(1), 3);
        assertEq(outputOracle.getL2OutputIndexAfter(100), 3);
        assertEq(outputOracle.getL2OutputIndexAfter(101), 3);
        assertEq(outputOracle.getL2OutputIndexAfter(200), 3);
        assertEq(outputOracle.getL2OutputIndexAfter(201), 3);
        assertEq(outputOracle.getL2OutputIndexAfter(300), 3);
        assertEq(outputOracle.getL2OutputIndexAfter(301), 4);
        assertEq(outputOracle.getL2OutputIndexAfter(400), 4);
        assertEq(outputOracle.getL2OutputIndexAfter(401), 5);
        assertEq(outputOracle.getL2OutputIndexAfter(500), 5);
        assertEq(outputOracle.getL2OutputIndexAfter(501), 0);
        assertEq(outputOracle.getL2OutputIndexAfter(600), 0);
        assertEq(outputOracle.getL2OutputIndexAfter(601), 1);
        assertEq(outputOracle.getL2OutputIndexAfter(700), 1);
        assertEq(outputOracle.getL2OutputIndexAfter(701), 2);
        assertEq(outputOracle.getL2OutputIndexAfter(800), 2);
        vm.expectRevert(bytes("L2OutputOracle: cannot get output for a block that has not been proposed"));
        outputOracle.getL2OutputIndexAfter(801);
    }
}
