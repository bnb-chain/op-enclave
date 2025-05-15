// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {L2Genesis} from "@opbnb-bedrock/scripts/L2Genesis.s.sol";
import {Deployer} from "@opbnb-bedrock/scripts/Deployer.sol";
import {console2 as console} from "forge-std/console2.sol";

contract L2GenesisDeploy is L2Genesis, Deployer {
    function generateForkAllocs() public {
        console.log("Generate fork allocs!");
        runWithAllUpgrades();
    }
}
