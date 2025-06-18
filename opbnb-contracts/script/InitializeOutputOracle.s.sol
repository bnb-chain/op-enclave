// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {stdJson} from "forge-std/StdJson.sol";
import {console2 as console} from "forge-std/console2.sol";

import {Hashing} from "@opbnb-bedrock/src/libraries/Hashing.sol";
import {Types as Types2} from "@opbnb-bedrock/src/libraries/Types.sol";
import {ChainAssertions} from "@opbnb-bedrock/scripts/ChainAssertions.sol";
import {Config} from "@opbnb-bedrock/scripts/Config.sol";
import {Deploy} from "@opbnb-bedrock/scripts/Deploy.s.sol";
import {DeployConfig} from "@opbnb-bedrock/scripts/DeployConfig.s.sol";
import {Types} from "@opbnb-bedrock/scripts/Types.sol";

import {L2OutputOracle} from "../src/L2OutputOracle.sol";

contract InitializeOutputOracle is Deploy {
    struct Hashes {
        bytes32 configHash;
        bytes32 genesisOutputRoot;
    }

    bytes32 public constant MESSAGE_PASSER_STORAGE_HASH =
        0x8ed4baae3a927be3dea54996b4d5899f8c01e7594bf50b17dc1e741388ce3d12;

    /// The initialization of the L2OutputOracle proxy
    function initializeNewL2OutputOracle() public broadcast {
        getAndSaveAddresses();

        console.log("Upgrading and initializing L2OutputOracle proxy");
        address l2OutputOracleProxy = mustGetAddress("L2OutputOracleProxy");
        address l2OutputOracle = mustGetAddress("L2OutputOracle");

        Hashes memory hashes = calculateHashes();
        _upgradeAndCallViaSafe({
            _proxy: payable(l2OutputOracleProxy),
            _implementation: l2OutputOracle,
            _innerCallData: abi.encodeCall(
                L2OutputOracle.initialize,
                (
                    cfg.l2OutputOracleSubmissionInterval(),
                    cfg.l2BlockTime(),
                    cfg.l2OutputOracleStartingBlockNumber(),
                    cfg.l2OutputOracleStartingTimestamp(),
                    cfg.l2OutputOracleProposer(),
                    cfg.l2OutputOracleChallenger(),
                    cfg.finalizationPeriodSeconds(),
                    hashes.configHash,
                    hashes.genesisOutputRoot,
                    true
                )
            )
        });

        L2OutputOracle oracle = L2OutputOracle(l2OutputOracleProxy);
        string memory version = oracle.version();
        console.log("L2OutputOracle version: %s", version);

        checkL2OutputOracle({_oracle: address(oracle), _cfg: cfg, _isProxy: true});
    }

    function getAndSaveAddresses() internal {
        string memory _path = Config.deploymentOutfile();
        string memory _json;

        try vm.readFile(_path) returns (string memory data) {
            _json = data;
        } catch {
            require(false, string.concat("Cannot find deployment file at ", _path));
        }

        address l2OutputOracleProxy = stdJson.readAddress(_json, "$.L2OutputOracleProxy");
        save("L2OutputOracleProxy", l2OutputOracleProxy);

        address l2OutputOracle = stdJson.readAddress(_json, "$.L2OutputOracle");
        save("L2OutputOracle", l2OutputOracle);

        address proxyAdmin = stdJson.readAddress(_json, "$.ProxyAdmin");
        save("ProxyAdmin", proxyAdmin);

        address safe = stdJson.readAddress(_json, "$.SystemOwnerSafe");
        save("SystemOwnerSafe", safe);
    }

    function checkL2OutputOracle(address _oracle, DeployConfig _cfg, bool _isProxy) internal view {
        console.log("Running chain assertions on the L2OutputOracle");
        L2OutputOracle oracle = L2OutputOracle(_oracle);

        // Check that the contract is initialized
        ChainAssertions.assertSlotValueIsOne({_contractAddress: address(oracle), _slot: 0, _offset: 0});

        if (_isProxy) {
            require(oracle.proposer() == _cfg.l2OutputOracleProposer());
        } else {
            require(oracle.proposer() == address(0));
        }
    }

    function calculateHashes() internal view returns (Hashes memory) {
        string memory _json;

        string memory _path = vm.envOr("ROLLUP_CONFIG_PATH", string(""));
        require(bytes(_path).length > 0, "Config: must set ROLLUP_CONFIG_PATH to filesystem path of rollup config");

        console.log("Rollup config: reading file %s", _path);
        try vm.readFile(_path) returns (string memory data) {
            _json = data;
        } catch {
            require(false, string.concat("Cannot find rollup config file at ", _path));
        }

        uint256 l2ChainID = stdJson.readUint(_json, "$.l2_chain_id");
        uint256 genesisL1Hash = stdJson.readUint(_json, "$.genesis.l1.hash");
        bytes32 genesisL2Hash = stdJson.readBytes32(_json, "$.genesis.l2.hash");
        uint64 l2Time = uint64(stdJson.readUint(_json, "$.genesis.l2_time"));
        address batcherAddr = stdJson.readAddress(_json, "$.genesis.system_config.batcherAddr");
        bytes32 scalar = stdJson.readBytes32(_json, "$.genesis.system_config.scalar");
        uint64 gasLimit = uint64(stdJson.readUint(_json, "$.genesis.system_config.gasLimit"));
        address depositContractAddr = stdJson.readAddress(_json, "$.deposit_contract_address");
        address l1SystemConfigAddr = stdJson.readAddress(_json, "$.l1_system_config_address");
        bytes32 l2GenesisStateRoot = stdJson.readBytes32(_json, "$.genesis.l2_genesis_state_root");

        bytes32 configHash = keccak256(
            abi.encodePacked(
                uint64(0), // version
                l2ChainID,
                genesisL1Hash,
                genesisL2Hash,
                l2Time,
                batcherAddr,
                scalar,
                gasLimit,
                depositContractAddr,
                l1SystemConfigAddr
            )
        );

        bytes32 genesisOutputRoot = Hashing.hashOutputRootProof(
            Types2.OutputRootProof({
                version: 0,
                stateRoot: l2GenesisStateRoot,
                messagePasserStorageRoot: MESSAGE_PASSER_STORAGE_HASH,
                latestBlockhash: genesisL2Hash
            })
        );

        return Hashes({configHash: configHash, genesisOutputRoot: genesisOutputRoot});
    }
}
