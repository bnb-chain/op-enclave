guard-%:
	@ if [ "${${*}}" = "" ]; then echo "Environment variable $* not set" && exit 1; fi

define abigen
	echo "Generating bindings for $(1)"
	cp opbnb-contracts/out/$(1).sol/$(1).$(3).json opbnb-contracts/out/$(1).sol/$(1).json 2>/dev/null || true
	jq -r '.bytecode.object' opbnb-contracts/out/$(1).sol/$(1).json > opbnb-contracts/out/$(1).sol/$(1).bin
	jq -r '.abi' opbnb-contracts/out/$(1).sol/$(1).json > opbnb-contracts/out/$(1).sol/$(1).abi
	abigen --abi opbnb-contracts/out/$(1).sol/$(1).abi --bin opbnb-contracts/out/$(1).sol/$(1).bin --pkg bindings --type $(1) --out bindings/$(2).go
endef

define verify
	deploy=$(1); \
	version=$(2); \
	addresses=$$(jq -r '.transactions[] | select(.transactionType=="CREATE" or .transactionType=="CREATE2") | .contractAddress' $$deploy); \
	for address in $$addresses; do \
		name=$$(jq -r --arg address "$$address" '.transactions[] | select((.transactionType=="CREATE" or .transactionType=="CREATE2") and .contractAddress==$$address) | .contractName' $$deploy); \
		arguments=$$(jq -r --arg address "$$address" '.transactions[] | select((.transactionType=="CREATE" or .transactionType=="CREATE2") and .contractAddress==$$address) | .arguments // [] | join(" ")' $$deploy); \
		namewithoutversion=$${name%.*.*.*}; \
		constructor=$$(jq '.abi[] | select(.type=="constructor")' contracts/out/$$namewithoutversion.sol/$$name.json | jq -r '.inputs | map(.type) | join(",")'); \
		echo; \
		echo "Verifying $$namewithoutversion @ $$address using constructor($$constructor) $$arguments"; \
		constructor_args=$$(cast abi-encode "constructor($$constructor)" $$arguments); \
		cd contracts; \
		forge verify-contract --compiler-version $$version --watch --verifier-url https://api-sepolia.basescan.org/api --constructor-args $$constructor_args $$address $$namewithoutversion; \
		cd ..; \
	done
endef

.PHONY: bindings
bindings:
	go install github.com/ethereum/go-ethereum/cmd/abigen@latest
	cd opbnb-contracts && forge build
	mkdir -p bindings
	@$(call abigen,"L2OutputOracle","l2_output_oracle","0.8.15")
	@$(call abigen,"Portal","portal","0.8.15")
	@$(call abigen,"DeployChain","deploy_chain","0.8.15")
	@$(call abigen,"CertManager","cert_manager","0.8.15")
	@$(call abigen,"NitroEnclavesManager","nitro_enclaves_manager","0.8.15")
	@$(call abigen,"GnosisSafe","gnosis_safe","0.8.15")

.PHONY: deploy-cert-manager
deploy-cert-manager: guard-IMPL_SALT guard-DEPLOY_PRIVATE_KEY guard-RPC_URL
	@cd contracts && forge script DeployCertManager --rpc-url $(RPC_URL) \
		--private-key $(DEPLOY_PRIVATE_KEY) --broadcast

.PHONY: deploy
deploy: guard-IMPL_SALT guard-DEPLOY_CONFIG_PATH guard-DEPLOY_PRIVATE_KEY guard-RPC_URL
	@cd contracts && forge script DeploySystem --sig deploy --rpc-url $(RPC_URL) \
		--private-key $(DEPLOY_PRIVATE_KEY) --broadcast

.PHONY: deploy-deploy-chain
deploy-deploy-chain: guard-IMPL_SALT guard-DEPLOY_PRIVATE_KEY guard-RPC_URL
	@cd contracts && forge script DeployDeployChain --rpc-url $(RPC_URL) \
		--private-key $(DEPLOY_PRIVATE_KEY) --broadcast

.PHONY: testnet
testnet: guard-L1_URL guard-DEPLOY_PRIVATE_KEY
	DEPLOY_CHAIN_ADDRESS=$${DEPLOY_CHAIN_ADDRESS:-$$(jq -r ".DeployChain" contracts/deployments/84532-deploy.json)} \
		go run ./testnet

.PHONY: verify
verify:
	@$(call verify,"contracts/broadcast/DeployCertManager.s.sol/84532/run-1736384133.json","0.8.24")
	@$(call verify,"contracts/broadcast/DeploySystem.s.sol/84532/run-1736385859.json","0.8.15")
	#@$(call verify,"contracts/broadcast/DeployDeployChain.s.sol/84532/run-1733884066.json","0.8.15")

.PHONY: op-batcher
op-batcher:
	@echo "Building op-batcher..."
	@mkdir -p build
	@cd op-batcher && go build -o ../build/op-batcher ./cmd/main.go
	@echo "op-batcher binary has been built and placed in build/ directory"

.PHONY: op-proposer
op-proposer:
	@echo "Building op-proposer..."
	@go mod tidy
	@mkdir -p build
	@cd op-proposer && go build -o ../build/op-proposer ./cmd/main.go
	@echo "op-proposer binary has been built and placed in build/ directory"

.PHONY: op-enclave
op-enclave:
	@echo "Building op-enclave..."
	@mkdir -p build
	@cd op-enclave && go mod tidy && go build -o ../build/op-enclave ./cmd/enclave/main.go
	@echo "op-enclave binary has been built and placed in build/ directory"
	@cd op-enclave && go mod tidy && go build -o ../build/op-enclave-server ./cmd/server/main.go
	@echo "op-enclave-server binary has been built and placed in build/ directory"

.PHONY: clear
clear:
	@echo "Cleaning build directory..."
	@rm -rf build
	@echo "Build directory has been cleaned"

.PHONY: all
all: op-batcher op-proposer op-enclave
	@echo "All components have been built successfully"