// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Artifacts} from "@opbnb-bedrock/scripts/Artifacts.s.sol";
import {ProxyAdmin} from "@opbnb-bedrock/src/universal/ProxyAdmin.sol";
import {NitroEnclavesManager} from "../src/NitroEnclavesManager.sol";
import {ICertManager} from "@nitro-validator/ICertManager.sol";
import {IGnosisSafe, Enum} from "@opbnb-bedrock/scripts/interfaces/IGnosisSafe.sol";

contract UpgradeNitroEnclavesManager is Script, Artifacts {
    function run() public {
        _loadAddresses(deploymentOutfile);

        bytes memory signature = abi.encodePacked(uint256(uint160(msg.sender)), bytes32(0), uint8(1));

        console.log("Deploying NitroEnclavesManager implementation");
        vm.startBroadcast();

        address addr_ =
            address(new NitroEnclavesManager{salt: _implSalt()}(ICertManager(mustGetAddress("CertManager"))));
        bytes memory data =
            abi.encodeCall(ProxyAdmin.upgrade, (payable(mustGetAddress("NitroEnclavesManagerProxy")), address(addr_)));
        IGnosisSafe(mustGetAddress("SystemOwnerSafe")).execTransaction({
            to: mustGetAddress("ProxyAdmin"),
            value: 0,
            data: data,
            operation: Enum.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(address(0)),
            signatures: signature
        });

        vm.stopBroadcast();

        delete _namedDeployments["NitroEnclavesManager"];
        save("NitroEnclavesManager", addr_);
    }

    function _implSalt() internal view returns (bytes32 _env) {
        _env = keccak256(bytes(vm.envOr("IMPL_SALT", string("ethers phoenix"))));
    }
}
