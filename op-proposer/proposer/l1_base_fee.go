package proposer

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum-optimism/optimism/op-node/rollup/derive"
	"github.com/ethereum-optimism/optimism/op-service/bsc"
	"github.com/ethereum-optimism/optimism/op-service/eth"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
)

var (
	_       derive.L1ReceiptsFetcher = &l1ReceiptsFetcher{}
	fetcher *l1ReceiptsFetcher
)

type l1ReceiptsFetcher struct {
	l1 L1Client
}

func (f *l1ReceiptsFetcher) ClearReceiptsCacheBefore(blockNum uint64) {
	// No-op implementation since this fetcher doesn't maintain a cache
}

func (f *l1ReceiptsFetcher) FetchReceipts(ctx context.Context, blockHash common.Hash) (eth.BlockInfo, types.Receipts, error) {
	return nil, nil, fmt.Errorf("FetchReceipts not implemented")
}

func (f *l1ReceiptsFetcher) GoOrUpdatePreFetchReceipts(ctx context.Context, blockNum uint64) error {
	// No-op implementation since this fetcher doesn't maintain a cache
	return nil
}

func (f *l1ReceiptsFetcher) InfoAndTxsByHash(ctx context.Context, hash common.Hash) (eth.BlockInfo, types.Transactions, error) {
	return f.l1.InfoAndTxsByHash(ctx, hash)
	//return nil, nil, fmt.Errorf("InfoAndTxsByHash not implemented")
}

func (f *l1ReceiptsFetcher) InfoByHash(ctx context.Context, hash common.Hash) (eth.BlockInfo, error) {
	return nil, fmt.Errorf("InfoByHash not implemented")
}

func (f *l1ReceiptsFetcher) PreFetchReceipts(ctx context.Context, blockHash common.Hash) (bool, error) {
	return false, nil // No-op implementation
}

// CalculateL1BaseFee calculates the L1 base fee for a given block.
func (p *Prover) calculateL1BaseFee(ctx context.Context, l2Parent eth.L2BlockRef, epoch eth.BlockID) (*big.Int, error) {
	var (
		l1BaseFee *big.Int
		err       error
	)
	if fetcher == nil {
		fetcher = &l1ReceiptsFetcher{l1: p.l1}
	}
	if p.rollupCfg.IsSnow(p.rollupCfg.NextSecondBlockTime(l2Parent.MillisecondTimestamp())) {
		l1BaseFee, err = calculateSnowL1GasPrice(ctx, fetcher, epoch)
		if err != nil {
			return nil, err
		}
	} else if p.rollupCfg.IsFermat(big.NewInt(int64(l2Parent.Number + 1))) {
		l1BaseFee = bsc.BaseFeeByNetworks(p.rollupCfg.L2ChainID)
	} else {
		_, transactions, err := fetcher.InfoAndTxsByHash(ctx, epoch.Hash)
		if err != nil {
			return nil, fmt.Errorf("failed to fetch L1 block info and txs: %w", err)
		}
		l1BaseFee = bsc.BaseFeeByTransactions(transactions)
	}
	return l1BaseFee, nil
}

func calculateSnowL1GasPrice(ctx context.Context, fetcher derive.L1ReceiptsFetcher, epoch eth.BlockID) (*big.Int, error) {
	ba := derive.NewFetchingAttributesBuilder(nil, fetcher, nil)
	l1BaseFee, err := derive.SnowL1GasPrice(ctx, ba, epoch)
	if err != nil {
		return nil, err
	}
	return l1BaseFee, nil
}
