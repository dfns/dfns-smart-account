// SPDX-License-Identifier : MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DfnsSmartAccount} from "../src/DfnsSmartAccount.sol";

contract DeployDfnsSmartAccount is Script {
    function run() external {
        vm.startBroadcast();
        new DfnsSmartAccount();
        vm.stopBroadcast();
    }
}
