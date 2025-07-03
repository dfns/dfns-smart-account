#!/bin/sh

# Usage: ./verify-all.sh <contract_address> <etherscan_api_key>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <contract_address> <etherscan_api_key>"
    exit 1
fi

CONTRACT_ADDRESS=$1
ETHERSCAN_API_KEY=$2

echo "Verifying contract $CONTRACT_ADDRESS on Polygon networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain polygon --verifier-api-key $ETHERSCAN_API_KEY --watch 
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain amoy --verifier-api-key $ETHERSCAN_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on Base networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain base --verifier-api-key $ETHERSCAN_API_KEY --watch 
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain base-sepolia --verifier-api-key $ETHERSCAN_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on ETH networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain holesky --verifier-api-key $ETHERSCAN_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain sepolia --verifier-api-key $ETHERSCAN_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain hoodi --verifier-api-key $ETHERSCAN_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain mainnet --verifier-api-key $ETHERSCAN_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on Optimism networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain optimism --verifier-api-key $ETHERSCAN_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain optimism-sepolia --verifier-api-key $ETHERSCAN_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on BSC networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain bsc --verifier-api-key $ETHERSCAN_API_KEY --watch
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain bsc-testnet --verifier-api-key $ETHERSCAN_API_KEY --watch
