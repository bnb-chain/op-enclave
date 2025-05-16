// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Artifacts} from "@opbnb-bedrock/scripts/Artifacts.s.sol";
import {Config} from "@opbnb-bedrock/scripts/Config.sol";
import {Executables} from "@opbnb-bedrock/scripts/Executables.sol";
import {console} from "forge-std/console.sol";
import {EnclaveDeployConfig} from "./EnclaveDeployConfig.s.sol";

/// @title EnclaveDeployer
/// @author tynes
/// @notice A contract that can make deploying and interacting with deployments easy.
abstract contract EnclaveDeployer is Script, Artifacts {
    EnclaveDeployConfig public constant enclaveCfg =
        EnclaveDeployConfig(address(uint160(uint256(keccak256(abi.encode("optimism.enclavedeployconfig"))))));

    /// @notice Sets up the artifacts contract.
    function setUp() public virtual override {
        Artifacts.setUp();

        console.log("Commit hash: %s", Executables.gitCommitHash());

        vm.etch(address(enclaveCfg), vm.getDeployedCode("EnclaveDeployConfig.s.sol:EnclaveDeployConfig"));
        vm.label(address(enclaveCfg), "EnclaveDeployConfig");
        vm.allowCheatcodes(address(enclaveCfg));
        enclaveCfg.read(Config.deployConfigPath());
    }
}
