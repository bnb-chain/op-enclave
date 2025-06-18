package enclave

import (
	"encoding/binary"
	"math/big"

	"github.com/ethereum-optimism/optimism/op-node/rollup"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/params"
)

const (
	version0 uint64 = 0
)

type ChainConfig struct {
	*params.ChainConfig
	*PerChainConfig
}

func NewChainConfig(cfg *PerChainConfig, chainConfig *params.ChainConfig) *ChainConfig {
	return &ChainConfig{
		ChainConfig:    chainConfig,
		PerChainConfig: cfg,
	}
}

type PerChainConfig struct {
	ChainID *big.Int `json:"chain_id"`

	Genesis   rollup.Genesis `json:"genesis"`
	BlockTime uint64         `json:"block_time"`

	DepositContractAddress common.Address `json:"deposit_contract_address"`
	L1SystemConfigAddress  common.Address `json:"l1_system_config_address"`

	RollupCfg *rollup.Config `json:"rollup_cfg"`
}

func FromRollupConfig(cfg *rollup.Config) *PerChainConfig {
	p := &PerChainConfig{
		ChainID:                cfg.L2ChainID,
		Genesis:                cfg.Genesis,
		BlockTime:              cfg.BlockTime,
		DepositContractAddress: cfg.DepositContractAddress,
		L1SystemConfigAddress:  cfg.L1SystemConfigAddress,
		RollupCfg:              cfg,
	}
	return p
}

func (p *PerChainConfig) ToRollupConfig() *rollup.Config {
	return p.RollupCfg
}

func (p *PerChainConfig) Hash() common.Hash {
	return crypto.Keccak256Hash(p.MarshalBinary())
}

func (p *PerChainConfig) MarshalBinary() (data []byte) {
	data = binary.BigEndian.AppendUint64(data, version0)
	chainIDBytes := p.ChainID.Bytes()
	data = append(data, make([]byte, 32-len(chainIDBytes))...)
	data = append(data, chainIDBytes...)
	data = append(data, p.Genesis.L1.Hash[:]...)
	data = append(data, p.Genesis.L2.Hash[:]...)
	data = binary.BigEndian.AppendUint64(data, p.Genesis.L2Time)
	data = append(data, p.Genesis.SystemConfig.BatcherAddr.Bytes()...)
	data = append(data, p.Genesis.SystemConfig.Scalar[:]...)
	data = binary.BigEndian.AppendUint64(data, p.Genesis.SystemConfig.GasLimit)
	data = append(data, p.DepositContractAddress.Bytes()...)
	data = append(data, p.L1SystemConfigAddress.Bytes()...)
	return data
}
