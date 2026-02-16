# Dfns Smart Account

## Introduction

This smart contract is heavily inspired from the SafeLite example: https://github.com/5afe/safe-eip7702/blob/main/safe-eip7702-contracts/contracts/experimental/SafeLite.sol
It was stripped from all unecessary logic to only keep the batch functionality.
It uses no dependency and rely on some assembly code to save gas usage.

After deployment, this contract is intended to be called by the [dfns.co](https://dfns.co) WaaS. It will be used for the Fee Sponsor feature:
A Dfns user can create 2 wallets:
- Wallet A (sponsor)
- Wallet B (sponsoree)

`Wallet A` will hold the gas token of the EVM chain (ETH, BNB, ...). `Wallet B` will hold various tokens (ERC20) but not necessarily the native token of the chain.
With the fee sponsor feature, `Wallet B` will be able to send some tokens without the need of paying the fees, they will be covered by `Wallet A`.

## Execution Steps of a Fee Sponsor Transaction

- Check whether or not `Wallet B` is pointing to the `Dfns Smart Account` contract address, using the `eth_getCode` [RPC Method](https://ethereum-json-rpc.com/?method=eth_getCode). 
  - If `Wallet B` does not have any code, sign an EIP-7702 Authorization, to make the EOA point to the `Dfns Smart Account` contract
  - If `Wallet B` already points to the `Dfns Smart Account`, do nothing
  - If `Wallet B` points to a smart contract which is not the `Dfns Smart Account`, abort the transaction 
- Build the transaction for `Wallet B` based on the intent of the user, and derive the three parameters: `to`, `value`, `data`, bundle it in the `userOps` data structure and sign it.
- Build a transaction with `Wallet A`:
  - Transaction type:
    - If an EIP-7702 Authorization was signed, add the Signed Authorization to the transaction: this will be a type 4 transaction
    - If no Authorization was signed, this will be a classic type 2 transaction
  - the `to` field of the transaction will be the `Wallet B` address
  - the `value` field will be `0`
  - the `data` field will be the smart contract call to execute to pass the signed userOps of Step 2 to the `handleOps` method.
- Broadcast the transaction:
  - `Wallet A` pays for the fees
  - `Wallet B` has its intent executed

## UserOps encoding

```typescript
import { concat, solidityPacked } from 'ethers'

const encodeUserOps = (userOps: { to: string, value: BigInt, data: Uint8Array }[]) => {
  return concat(userOps.map((userOp) =>
    solidityPacked(['address', 'uint256', 'uint256', 'bytes'], [userOp.to, userOp.value, BigInt(userOp.data.length), userOp.data])
  ))
}
```

## UserOps signing

```typescript
import { TypedDataEncoder, keccak256 } from 'ethers'

const types = {
  HandleOps: [
    { name: 'data', type: 'bytes32' },
    { name: 'nonce', type: 'uint256' },
    { name: 'sponsor', type: 'address' }
  ],
}
const sponsor = '0x1234...'
const nonce = await jsonRpcProvider.getStorage(walletBAddress, '0x10ee8db8a0021e326896fcf9b44ce61becefe5f52e3dfd0bb294aee9b73bc000')
const domain = { chainId, verifyingContract: walletBAddress }
const encodedUserOps = encodeUserOps(userOps)
const signedUserOps = keccak256(encodedUserOps)
const message = { data: signedUserOps, nonce, sponsor }
const toSign = TypedDataEncoder.hash(domain, types, message)
const userOpsSignature = sign(toSign) 
```

## handleOps data

```typescript
import { Signature } from 'ethers'

const { r, yParityAndS } = Signature.from(userOpsSignature)
const handleOpsData = new Interface(['function handleOps( bytes memory userOps, uint256 r, uint256 vs ) public payable']).encodeFunctionData('handleOps', [
  encodedUserOps,
  r,
  yParityAndS,
])
```

## Deployment

It is deployed on the following chains:

| Blockchain          | Contract Address                                                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Arbitrum One        | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://arbiscan.io/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                         |
| Arbitrum Sepolia    | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://sepolia.arbiscan.io/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                 |
| Base                | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://basescan.org/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                        |
| Base Sepolia        | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://sepolia.basescan.org/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                |
| Berachain           | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://berascan.com/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                        |
| Berachain Bepolia   | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://testnet.berascan.com/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                |
| Binance Smart Chain | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://bscscan.com/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                         |
| Binance Testnet     | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://testnet.bscscan.com/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                 |
| Ethereum Mainnet    | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://etherscan.io/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                        |
| Ethereum Hoodi      | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://hoodi.etherscan.io/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                  |
| Ethereum Sepolia    | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://sepolia.etherscan.io/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                |
| Flow EVM            | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://evm.flowscan.io/address/0xcEa43594f38316F0e01c161D8DaBDe0a07a1F512?tab=contract)             |
| Flow EVM Testnet    | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://evm-testnet.flowscan.io/address/0xcEa43594f38316F0e01c161D8DaBDe0a07a1F512?tab=contract)       |
| Optimism            | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://optimistic.etherscan.io/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)             |
| Optimism Sepolia    | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://sepolia-optimism.etherscan.io/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)       |
| Plasma              | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://plasmascan.to/address/0xcEa43594f38316F0e01c161D8DaBDe0a07a1F512/contract/9745/code)                     |
| Plasma Testnet      | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://testnet.plasmascan.to/address/0xcEa43594f38316F0e01c161D8DaBDe0a07a1F512/contract/9745/code)                |
| Polygon             | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://polygonscan.com/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                     |
| Polygon Amoy        | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://amoy.polygonscan.com/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)                |


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge create src/DfnsSmartAccount.sol:DfnsSmartAccount --rpc-url <your_rpc_url> --private-key <dummy_private_key>
```

This is a dry run, use a dummy private key as this is not the real deployment. After running the command, forge will output a Transaction with a Json format, copy the "input" field, and use the Dfns API to broadcast the transaction:

`POST https://{{customerApiDomain}}/wallets/:walletId/transactions`

```json
{
  "kind": "Json",
  "transaction": {
    "data": "0x6080604052348015600e575f5ffd5b50610fe28061001c5f395ff3fe608060405260043610610058575f3560e01c806301ffc9a714610063578063150b7a021461009f57806374fa4121146100db578063bc197c81146100f7578063d087d28814610133578063f23a6e611461015d5761005f565b3661005f57005b5f5ffd5b34801561006e575f5ffd5b5061008960048036038101906100849190610839565b610199565b604051610096919061087e565b60405180910390f35b3480156100aa575f5ffd5b506100c560048036038101906100c09190610985565b61029a565b6040516100d29190610a18565b60405180910390f35b6100f560048036038101906100f09190610b69565b6102ae565b005b348015610102575f5ffd5b5061011d60048036038101906101189190610c2a565b6104a5565b60405161012a9190610a18565b60405180910390f35b34801561013e575f5ffd5b506101476104bc565b6040516101549190610d10565b60405180910390f35b348015610168575f5ffd5b50610183600480360381019061017e9190610d29565b6104cd565b6040516101909190610a18565b60405180910390f35b5f7f4e2312e0000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916148061026357507f150b7a02000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916145b8061029357506301ffc9a760e01b827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916145b9050919050565b5f63150b7a0260e01b905095945050505050565b5f6102b76104e2565b90505f815f015490505f7f47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a794692185f1b46306040516020016102f893929190610de6565b6040516020818303038152906040528051906020012090505f7f4d45d6aca00518e5f826ef561e48d49260fb16644409228c5e739cb8f3c7c68e5f1b878051906020012084336040516020016103519493929190610e1b565b6040516020818303038152906040528051906020012090505f828260405160200161037d929190610ed2565b6040516020818303038152906040528051906020012090506103ae875f1b875f1b836105099092919063ffffffff16565b73ffffffffffffffffffffffffffffffffffffffff163073ffffffffffffffffffffffffffffffffffffffff1614610412576040517f8baa579f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60018401855f0181905550875160205b8181101561049957808a015160601c80610443576382d5d76a5f526004601cfd5b601482018b0151603483018c0151808401858111156104695763b4120f145f526004601cfd5b605485018e015f5f848387895af15f8103610486573d5f5f3e3d5ffd5b8360540187019650505050505050610422565b50505050505050505050565b5f63bc197c8160e01b905098975050505050505050565b5f6104c56104e2565b5f0154905090565b5f63f23a6e6160e01b90509695505050505050565b5f7f10ee8db8a0021e326896fcf9b44ce61becefe5f52e3dfd0bb294aee9b73bc000905090565b5f5f5f5f610518878787610535565b925092509250610528828261058a565b8293505050509392505050565b5f5f5f5f7f7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5f1b851690505f601b60ff875f1c901c019050610579888289856106ec565b945094509450505093509350939050565b5f600381111561059d5761059c610f08565b5b8260038111156105b0576105af610f08565b5b03156106e857600160038111156105ca576105c9610f08565b5b8260038111156105dd576105dc610f08565b5b03610614576040517ff645eedf00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6002600381111561062857610627610f08565b5b82600381111561063b5761063a610f08565b5b0361067f57805f1c6040517ffce698f70000000000000000000000000000000000000000000000000000000081526004016106769190610d10565b60405180910390fd5b60038081111561069257610691610f08565b5b8260038111156106a5576106a4610f08565b5b036106e757806040517fd78bce0c0000000000000000000000000000000000000000000000000000000081526004016106de9190610f35565b60405180910390fd5b5b5050565b5f5f5f7f7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0845f1c1115610728575f6003859250925092506107c9565b5f6001888888886040515f815260200160405260405161074b9493929190610f69565b6020604051602081039080840390855afa15801561076b573d5f5f3e3d5ffd5b5050506020604051035190505f73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16036107bc575f60015f5f1b935093509350506107c9565b805f5f5f1b935093509350505b9450945094915050565b5f604051905090565b5f5ffd5b5f5ffd5b5f7fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b610818816107e4565b8114610822575f5ffd5b50565b5f813590506108338161080f565b92915050565b5f6020828403121561084e5761084d6107dc565b5b5f61085b84828501610825565b91505092915050565b5f8115159050919050565b61087881610864565b82525050565b5f6020820190506108915f83018461086f565b92915050565b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f6108c082610897565b9050919050565b6108d0816108b6565b81146108da575f5ffd5b50565b5f813590506108eb816108c7565b92915050565b5f819050919050565b610903816108f1565b811461090d575f5ffd5b50565b5f8135905061091e816108fa565b92915050565b5f5ffd5b5f5ffd5b5f5ffd5b5f5f83601f84011261094557610944610924565b5b8235905067ffffffffffffffff81111561096257610961610928565b5b60208301915083600182028301111561097e5761097d61092c565b5b9250929050565b5f5f5f5f5f6080868803121561099e5761099d6107dc565b5b5f6109ab888289016108dd565b95505060206109bc888289016108dd565b94505060406109cd88828901610910565b935050606086013567ffffffffffffffff8111156109ee576109ed6107e0565b5b6109fa88828901610930565b92509250509295509295909350565b610a12816107e4565b82525050565b5f602082019050610a2b5f830184610a09565b92915050565b5f5ffd5b5f601f19601f8301169050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b610a7b82610a35565b810181811067ffffffffffffffff82111715610a9a57610a99610a45565b5b80604052505050565b5f610aac6107d3565b9050610ab88282610a72565b919050565b5f67ffffffffffffffff821115610ad757610ad6610a45565b5b610ae082610a35565b9050602081019050919050565b828183375f83830152505050565b5f610b0d610b0884610abd565b610aa3565b905082815260208101848484011115610b2957610b28610a31565b5b610b34848285610aed565b509392505050565b5f82601f830112610b5057610b4f610924565b5b8135610b60848260208601610afb565b91505092915050565b5f5f5f60608486031215610b8057610b7f6107dc565b5b5f84013567ffffffffffffffff811115610b9d57610b9c6107e0565b5b610ba986828701610b3c565b9350506020610bba86828701610910565b9250506040610bcb86828701610910565b9150509250925092565b5f5f83601f840112610bea57610be9610924565b5b8235905067ffffffffffffffff811115610c0757610c06610928565b5b602083019150836020820283011115610c2357610c2261092c565b5b9250929050565b5f5f5f5f5f5f5f5f60a0898b031215610c4657610c456107dc565b5b5f610c538b828c016108dd565b9850506020610c648b828c016108dd565b975050604089013567ffffffffffffffff811115610c8557610c846107e0565b5b610c918b828c01610bd5565b9650965050606089013567ffffffffffffffff811115610cb457610cb36107e0565b5b610cc08b828c01610bd5565b9450945050608089013567ffffffffffffffff811115610ce357610ce26107e0565b5b610cef8b828c01610930565b92509250509295985092959890939650565b610d0a816108f1565b82525050565b5f602082019050610d235f830184610d01565b92915050565b5f5f5f5f5f5f60a08789031215610d4357610d426107dc565b5b5f610d5089828a016108dd565b9650506020610d6189828a016108dd565b9550506040610d7289828a01610910565b9450506060610d8389828a01610910565b935050608087013567ffffffffffffffff811115610da457610da36107e0565b5b610db089828a01610930565b92509250509295509295509295565b5f819050919050565b610dd181610dbf565b82525050565b610de0816108b6565b82525050565b5f606082019050610df95f830186610dc8565b610e066020830185610d01565b610e136040830184610dd7565b949350505050565b5f608082019050610e2e5f830187610dc8565b610e3b6020830186610dc8565b610e486040830185610d01565b610e556060830184610dd7565b95945050505050565b5f81905092915050565b7f19010000000000000000000000000000000000000000000000000000000000005f82015250565b5f610e9c600283610e5e565b9150610ea782610e68565b600282019050919050565b5f819050919050565b610ecc610ec782610dbf565b610eb2565b82525050565b5f610edc82610e90565b9150610ee88285610ebb565b602082019150610ef88284610ebb565b6020820191508190509392505050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52602160045260245ffd5b5f602082019050610f485f830184610dc8565b92915050565b5f60ff82169050919050565b610f6381610f4e565b82525050565b5f608082019050610f7c5f830187610dc8565b610f896020830186610f5a565b610f966040830185610dc8565b610fa36060830184610dc8565b9594505050505056fea2646970667358221220baad1d1b8ddf1f70f62632f341d7a40f7f47cf547e1e65a870cc641e8d7726bb64736f6c634300081d0033"
  }
}
```

```shell
./verify-all.sh <contract_address> <etherscan_api_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
