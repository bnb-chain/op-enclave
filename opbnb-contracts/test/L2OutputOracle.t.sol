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
        NitroEnclavesManager nemImpl = new NitroEnclavesManager(ICertManager(address(0)));
        NitroEnclavesManager nem =
            NitroEnclavesManager(ResolvingProxyFactory.setupProxy(address(nemImpl), address(admin), 0x00));
        nem.initialize({_owner: address(this), _manager: address(this)});
        nem.setProposer(address(this));
        L2OutputOracle l2OutputOracleImpl = new L2OutputOracle({_nitroEnclavesManager: nem});
        l2OutputOracle =
            L2OutputOracle(ResolvingProxyFactory.setupProxy(address(l2OutputOracleImpl), address(admin), 0x00));
        l2OutputOracle.initialize({
            _submissionInterval: 3600,
            _l2BlockTime: 1,
            _startingBlockNumber: 0,
            _startingTimestamp: 0,
            _proposer: address(this),
            _challenger: address(this),
            _finalizationPeriodSeconds: 0,
            _configHash: bytes32(0),
            _genesisOutputRoot: bytes32(0),
            _proofsEnabled: false
        });
    }

    function test_getL2OutputIndexAfter() public {
        // only genesis proposed
        assertEq(l2OutputOracle.getL2OutputIndexAfter(0), 0);
        vm.expectRevert(bytes("L2OutputOracle: cannot get output for a block that has not been proposed"));
        l2OutputOracle.getL2OutputIndexAfter(1);

        vm.warp(10000);
        // propose block 100 (index 1)
        l2OutputOracle.proposeL2Output(bytes32(uint256(1)), 100, 0, 0, "");
        assertEq(l2OutputOracle.getL2OutputIndexAfter(0), 0);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(1), 1);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(100), 1);
        vm.expectRevert(bytes("L2OutputOracle: cannot get output for a block that has not been proposed"));
        l2OutputOracle.getL2OutputIndexAfter(101);

        // propose block 200 (index 2)
        l2OutputOracle.proposeL2Output(bytes32(uint256(2)), 200, 0, 0, "");
        assertEq(l2OutputOracle.getL2OutputIndexAfter(0), 0);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(1), 1);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(100), 1);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(101), 2);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(200), 2);
        vm.expectRevert(bytes("L2OutputOracle: cannot get output for a block that has not been proposed"));
        l2OutputOracle.getL2OutputIndexAfter(201);

        // propose blocks 300 (3), 400 (4), 500 (5), 600 (6), 700 (7), 800 (8)
        l2OutputOracle.proposeL2Output(bytes32(uint256(3)), 300, 0, 0, "");
        l2OutputOracle.proposeL2Output(bytes32(uint256(4)), 400, 0, 0, "");
        l2OutputOracle.proposeL2Output(bytes32(uint256(5)), 500, 0, 0, "");
        l2OutputOracle.proposeL2Output(bytes32(uint256(6)), 600, 0, 0, "");
        l2OutputOracle.proposeL2Output(bytes32(uint256(7)), 700, 0, 0, "");
        l2OutputOracle.proposeL2Output(bytes32(uint256(7)), 800, 0, 0, "");
        assertEq(l2OutputOracle.getL2OutputIndexAfter(0), 0);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(1), 1);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(100), 1);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(101), 2);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(200), 2);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(201), 3);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(300), 3);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(301), 4);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(400), 4);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(401), 5);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(500), 5);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(501), 6);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(600), 6);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(601), 7);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(700), 7);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(701), 8);
        assertEq(l2OutputOracle.getL2OutputIndexAfter(800), 8);
        vm.expectRevert(bytes("L2OutputOracle: cannot get output for a block that has not been proposed"));
        l2OutputOracle.getL2OutputIndexAfter(801);
    }
}
