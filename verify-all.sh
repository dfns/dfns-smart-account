#!/bin/sh

# Usage: ./verify-all.sh <contract_address> <etherscan_api_key>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <contract_address> <etherscan_api_key>"
    exit 1
fi

CONTRACT_ADDRESS=$1
ETHERSCAN_API_KEY=$2

# echo "Verifying contract $CONTRACT_ADDRESS on Avalanche networks..."
# forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url 'https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan' --etherscan-api-key "verifyContract"
# forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/43113/etherscan' --etherscan-api-key "verifyContract"

echo "Verifying contract $CONTRACT_ADDRESS on Berachain networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain berachain --verifier-api-key $ETHERSCAN_API_KEY --watch 
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain berachain-bepolia --verifier-api-key $ETHERSCAN_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on Arbitrum networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain arbitrum --verifier-api-key $ETHERSCAN_API_KEY --watch 
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain arbitrum-sepolia --verifier-api-key $ETHERSCAN_API_KEY --watch

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

echo "Verifying contract $CONTRACT_ADDRESS on Plasma networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --verifier etherscan --chain plasma --verifier-api-key $ETHERSCAN_API_KEY --watch

echo "Verifying contract $CONTRACT_ADDRESS on Flow networks..."
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --rpc-url https://mainnet.evm.nodes.onflow.org/ --verifier blockscout --verifier-url 'https://evm.flowscan.io/api/'
forge verify-contract $CONTRACT_ADDRESS ./src/DfnsSmartAccount.sol:DfnsSmartAccount --rpc-url https://testnet.evm.nodes.onflow.org/ --verifier blockscout --verifier-url 'https://evm-testnet.flowscan.io/api/'
