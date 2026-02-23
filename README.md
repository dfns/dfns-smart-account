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

| Blockchain          | Contract Address                                                                                                                              |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Arbitrum One        | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://arbiscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)                     |
| Arbitrum Sepolia    | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://sepolia.arbiscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)             |
| Base                | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://basescan.org/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)                    |
| Base Sepolia        | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://sepolia.basescan.org/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)            |
| Berachain           | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://berascan.com/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)                    |
| Berachain Bepolia   | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://testnet.berascan.com/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)            |
| Binance Smart Chain | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://bscscan.com/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)                     |
| Binance Testnet     | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://testnet.bscscan.com/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)             |
| Ethereum Mainnet    | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://etherscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)                    |
| Ethereum Hoodi      | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://hoodi.etherscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)              |
| Ethereum Sepolia    | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://sepolia.etherscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)            |
| Flow EVM            | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://evm.flowscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e?tab=contract)         |
| Flow EVM Testnet    | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://evm-testnet.flowscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e?tab=contract) |
| Optimism            | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://optimistic.etherscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)         |
| Optimism Sepolia    | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://sepolia-optimism.etherscan.io/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)   |
| Plasma              | [0xf5138ba9777a42f76437ecd5f3cdb96decd72b4e](https://plasmascan.to/address/0xf5138ba9777a42f76437ecd5f3cdb96decd72b4e#code)                   |
| Plasma Testnet      | [0xa34e1e389097409aa65ff374af50b402e4a8f5c3](https://testnet.plasmascan.to/address/0xa34e1e389097409aa65ff374af50b402e4a8f5c3#code)           |
| Polygon             | [0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e](https://polygonscan.com/address/0xf5138ba9777A42F76437Ecd5F3cDb96Decd72b4e#code)                 |
| Polygon Amoy        | [0xcea43594f38316f0e01c161d8dabde0a07a1f512](https://amoy.polygonscan.com/address/0xcea43594f38316f0e01c161d8dabde0a07a1f512#code)            |


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
    "data": "0x6080604052348015600e575f5ffd5b506111a98061001c5f395ff3fe608060405260043610610073575f3560e01c806374fa41211161004d57806374fa412114610132578063bc197c811461014e578063d087d2881461018a578063f23a6e61146101b45761007a565b806301ffc9a71461007e578063150b7a02146100ba5780631626ba7e146100f65761007a565b3661007a57005b5f5ffd5b348015610089575f5ffd5b506100a4600480360381019061009f919061092a565b6101f0565b6040516100b1919061096f565b60405180910390f35b3480156100c5575f5ffd5b506100e060048036038101906100db9190610a76565b6102f1565b6040516100ed9190610b09565b60405180910390f35b348015610101575f5ffd5b5061011c60048036038101906101179190610c8d565b610305565b6040516101299190610b09565b60405180910390f35b61014c60048036038101906101479190610ce7565b61039c565b005b348015610159575f5ffd5b50610174600480360381019061016f9190610da8565b610596565b6040516101819190610b09565b60405180910390f35b348015610195575f5ffd5b5061019e6105ad565b6040516101ab9190610e8e565b60405180910390f35b3480156101bf575f5ffd5b506101da60048036038101906101d59190610ea7565b6105be565b6040516101e79190610b09565b60405180910390f35b5f7f4e2312e0000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff191614806102ba57507f150b7a02000000000000000000000000000000000000000000000000000000007bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916145b806102ea57506301ffc9a760e01b827bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916145b9050919050565b5f63150b7a0260e01b905095945050505050565b5f604082511461031a575f60e01b9050610396565b5f5f838060200190518101906103309190610f51565b9150915061034d825f1b825f1b876105d39092919063ffffffff16565b73ffffffffffffffffffffffffffffffffffffffff163073ffffffffffffffffffffffffffffffffffffffff1614610388575f60e01b610391565b631626ba7e60e01b5b925050505b92915050565b5f6103a56105ff565b90505f815f015490505f7f47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a794692185f1b46306040516020016103e693929190610fad565b6040516020818303038152906040528051906020012090505f7f4d45d6aca00518e5f826ef561e48d49260fb16644409228c5e739cb8f3c7c68e5f1b8780519060200120843360405160200161043f9493929190610fe2565b6040516020818303038152906040528051906020012090505f828260405160200161046b929190611099565b60405160208183030381529060405280519060200120905061049c875f1b875f1b836105d39092919063ffffffff16565b73ffffffffffffffffffffffffffffffffffffffff163073ffffffffffffffffffffffffffffffffffffffff1614610500576040517f8baa579f00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60018401855f018190555087516020810160205b8181101561058957808b015160601c80610535576382d5d76a5f526004601cfd5b601482018c0151603483018d01518060540184018581111561055e5763b4120f145f526004601cfd5b605485018f015f5f848387895af15f810361057b573d5f5f3e3d5ffd5b829650505050505050610514565b5050505050505050505050565b5f63bc197c8160e01b905098975050505050505050565b5f6105b66105ff565b5f0154905090565b5f63f23a6e6160e01b90509695505050505050565b5f5f5f5f6105e2878787610626565b9250925092506105f2828261067b565b8293505050509392505050565b5f7f10ee8db8a0021e326896fcf9b44ce61becefe5f52e3dfd0bb294aee9b73bc000905090565b5f5f5f5f7f7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5f1b851690505f601b60ff875f1c901c01905061066a888289856107dd565b945094509450505093509350939050565b5f600381111561068e5761068d6110cf565b5b8260038111156106a1576106a06110cf565b5b03156107d957600160038111156106bb576106ba6110cf565b5b8260038111156106ce576106cd6110cf565b5b03610705576040517ff645eedf00000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60026003811115610719576107186110cf565b5b82600381111561072c5761072b6110cf565b5b0361077057805f1c6040517ffce698f70000000000000000000000000000000000000000000000000000000081526004016107679190610e8e565b60405180910390fd5b600380811115610783576107826110cf565b5b826003811115610796576107956110cf565b5b036107d857806040517fd78bce0c0000000000000000000000000000000000000000000000000000000081526004016107cf91906110fc565b60405180910390fd5b5b5050565b5f5f5f7f7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0845f1c1115610819575f6003859250925092506108ba565b5f6001888888886040515f815260200160405260405161083c9493929190611130565b6020604051602081039080840390855afa15801561085c573d5f5f3e3d5ffd5b5050506020604051035190505f73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16036108ad575f60015f5f1b935093509350506108ba565b805f5f5f1b935093509350505b9450945094915050565b5f604051905090565b5f5ffd5b5f5ffd5b5f7fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b610909816108d5565b8114610913575f5ffd5b50565b5f8135905061092481610900565b92915050565b5f6020828403121561093f5761093e6108cd565b5b5f61094c84828501610916565b91505092915050565b5f8115159050919050565b61096981610955565b82525050565b5f6020820190506109825f830184610960565b92915050565b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f6109b182610988565b9050919050565b6109c1816109a7565b81146109cb575f5ffd5b50565b5f813590506109dc816109b8565b92915050565b5f819050919050565b6109f4816109e2565b81146109fe575f5ffd5b50565b5f81359050610a0f816109eb565b92915050565b5f5ffd5b5f5ffd5b5f5ffd5b5f5f83601f840112610a3657610a35610a15565b5b8235905067ffffffffffffffff811115610a5357610a52610a19565b5b602083019150836001820283011115610a6f57610a6e610a1d565b5b9250929050565b5f5f5f5f5f60808688031215610a8f57610a8e6108cd565b5b5f610a9c888289016109ce565b9550506020610aad888289016109ce565b9450506040610abe88828901610a01565b935050606086013567ffffffffffffffff811115610adf57610ade6108d1565b5b610aeb88828901610a21565b92509250509295509295909350565b610b03816108d5565b82525050565b5f602082019050610b1c5f830184610afa565b92915050565b5f819050919050565b610b3481610b22565b8114610b3e575f5ffd5b50565b5f81359050610b4f81610b2b565b92915050565b5f5ffd5b5f601f19601f8301169050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b610b9f82610b59565b810181811067ffffffffffffffff82111715610bbe57610bbd610b69565b5b80604052505050565b5f610bd06108c4565b9050610bdc8282610b96565b919050565b5f67ffffffffffffffff821115610bfb57610bfa610b69565b5b610c0482610b59565b9050602081019050919050565b828183375f83830152505050565b5f610c31610c2c84610be1565b610bc7565b905082815260208101848484011115610c4d57610c4c610b55565b5b610c58848285610c11565b509392505050565b5f82601f830112610c7457610c73610a15565b5b8135610c84848260208601610c1f565b91505092915050565b5f5f60408385031215610ca357610ca26108cd565b5b5f610cb085828601610b41565b925050602083013567ffffffffffffffff811115610cd157610cd06108d1565b5b610cdd85828601610c60565b9150509250929050565b5f5f5f60608486031215610cfe57610cfd6108cd565b5b5f84013567ffffffffffffffff811115610d1b57610d1a6108d1565b5b610d2786828701610c60565b9350506020610d3886828701610a01565b9250506040610d4986828701610a01565b9150509250925092565b5f5f83601f840112610d6857610d67610a15565b5b8235905067ffffffffffffffff811115610d8557610d84610a19565b5b602083019150836020820283011115610da157610da0610a1d565b5b9250929050565b5f5f5f5f5f5f5f5f60a0898b031215610dc457610dc36108cd565b5b5f610dd18b828c016109ce565b9850506020610de28b828c016109ce565b975050604089013567ffffffffffffffff811115610e0357610e026108d1565b5b610e0f8b828c01610d53565b9650965050606089013567ffffffffffffffff811115610e3257610e316108d1565b5b610e3e8b828c01610d53565b9450945050608089013567ffffffffffffffff811115610e6157610e606108d1565b5b610e6d8b828c01610a21565b92509250509295985092959890939650565b610e88816109e2565b82525050565b5f602082019050610ea15f830184610e7f565b92915050565b5f5f5f5f5f5f60a08789031215610ec157610ec06108cd565b5b5f610ece89828a016109ce565b9650506020610edf89828a016109ce565b9550506040610ef089828a01610a01565b9450506060610f0189828a01610a01565b935050608087013567ffffffffffffffff811115610f2257610f216108d1565b5b610f2e89828a01610a21565b92509250509295509295509295565b5f81519050610f4b816109eb565b92915050565b5f5f60408385031215610f6757610f666108cd565b5b5f610f7485828601610f3d565b9250506020610f8585828601610f3d565b9150509250929050565b610f9881610b22565b82525050565b610fa7816109a7565b82525050565b5f606082019050610fc05f830186610f8f565b610fcd6020830185610e7f565b610fda6040830184610f9e565b949350505050565b5f608082019050610ff55f830187610f8f565b6110026020830186610f8f565b61100f6040830185610e7f565b61101c6060830184610f9e565b95945050505050565b5f81905092915050565b7f19010000000000000000000000000000000000000000000000000000000000005f82015250565b5f611063600283611025565b915061106e8261102f565b600282019050919050565b5f819050919050565b61109361108e82610b22565b611079565b82525050565b5f6110a382611057565b91506110af8285611082565b6020820191506110bf8284611082565b6020820191508190509392505050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52602160045260245ffd5b5f60208201905061110f5f830184610f8f565b92915050565b5f60ff82169050919050565b61112a81611115565b82525050565b5f6080820190506111435f830187610f8f565b6111506020830186611121565b61115d6040830185610f8f565b61116a6060830184610f8f565b9594505050505056fea264697066735822122096b657e2b1046e5e647c100864da89bc0f5222109b70a126fd75f81f8967e26764736f6c634300081d0033"
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
