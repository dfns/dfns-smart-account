#!/bin/sh

# Usage: ./verify-all.sh <contract_address> <etherscan_eth_api_key> <etherscan_bnb_api_key> <etherscan_optimism_api_key> <etherscan_base_api_key>

if [ $# -ne 5 ]; then
    echo "Usage: $0 <contract_address> <etherscan_eth_api_key> <etherscan_bnb_api_key> <etherscan_optimism_api_key> <etherscan_base_api_key>"
    exit 1
fi

CONTRACT_ADDRESS=$1
ETHERSCAN_ETH_API_KEY=$2
ETHERSCAN_BINANCE_API_KEY=$3
ETHERSCAN_OPTIMISM_API_KEY=$4
ETHERSCAN_BASE_API_KEY=$5

echo "Verifying contract $CONTRACT_ADDRESS on ETH networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api-holesky.etherscan.io/api --etherscan-api-key $ETHERSCAN_ETH_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api-sepolia.etherscan.io/api --etherscan-api-key $ETHERSCAN_ETH_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api-hoodi.etherscan.io/api --etherscan-api-key $ETHERSCAN_ETH_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api.etherscan.io/api --etherscan-api-key $ETHERSCAN_ETH_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on BNB networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api.bscscan.com/api --etherscan-api-key $ETHERSCAN_BINANCE_API_KEY --watch 
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api-testnet.bscscan.com/api --etherscan-api-key $ETHERSCAN_BINANCE_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on Optimism networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api-sepolia-optimistic.etherscan.io/api --etherscan-api-key $ETHERSCAN_OPTIMISM_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api-optimistic.etherscan.io/api --etherscan-api-key $ETHERSCAN_OPTIMISM_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on Base networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api.basescan.org/api --etherscan-api-key $ETHERSCAN_BASE_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url https://api-sepolia.basescan.org/api --etherscan-api-key $ETHERSCAN_BASE_API_KEY --watch
