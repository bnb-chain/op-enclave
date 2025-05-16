// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdJson} from "forge-std/StdJson.sol";
import {DeployConfig} from "@opbnb-bedrock/scripts/DeployConfig.s.sol";

contract EnclaveDeployConfig is DeployConfig {
    address public certManager;
    bool public proofEnabled;
    bytes32 public genesisOutputRoot;
    bytes32 public configHash;

    function readNewConfig(string memory _path) public {
        read(_path);

        certManager = stdJson.readAddress(_json, "$.certManager");
        proofEnabled = stdJson.readBool(_json, "$.proofEnabled");
        genesisOutputRoot = stdJson.readBytes32(_json, "$.genesisOutputRoot");
        configHash = stdJson.readBytes32(_json, "$.configHash");
    }
}
