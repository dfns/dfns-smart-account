// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {DfnsSmartAccount} from "../src/DfnsSmartAccount.sol";

error InvalidSignature();

contract DfnsSmartAccountTest is Test {
    DfnsSmartAccount public dfnsSmartAccount;

    // test vector from holesky
    bytes userOps =
        hex"f56636f7ed43068bebe9d5dc7486e70d10bca5ac00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044a9059cbb000000000000000000000000e5a2ebc128e262ab1e3bd02bffbe16911adfbffb0000000000000000000000000000000000000000000000000de0b6b3a7640000";
    uint256 r =
        64343428091677375059052746335662367138860620239941235028252715491189038702595;
    uint256 vs =
        37550603490270631311168088709358492886626118254290512068767606772455083001294;

    function setUp() public {
        // Holesky chain id
        vm.chainId(17000);
        address contractAddress = 0xa570148Ab35de51eA1C59AC09Cc6ea37AC6BaB91;
        deployCodeTo("DfnsSmartAccount.sol", contractAddress);
        dfnsSmartAccount = DfnsSmartAccount(contractAddress);
    }

    function test_handleOps() public {
        assertEq(dfnsSmartAccount.getNonce(), 0);
        dfnsSmartAccount.handleOps(userOps, r, vs);
        assertEq(dfnsSmartAccount.getNonce(), 1);
    }

    function test_handleOpsWrongSignature() public {
        assertEq(dfnsSmartAccount.getNonce(), 0);
        vm.expectRevert(InvalidSignature.selector);
        dfnsSmartAccount.handleOps(userOps, r, vs + 1);
        assertEq(dfnsSmartAccount.getNonce(), 0);
    }

    function test_handleOpsReplayProtection() public {
        assertEq(dfnsSmartAccount.getNonce(), 0);
        dfnsSmartAccount.handleOps(userOps, r, vs);
        vm.expectRevert(InvalidSignature.selector);
        dfnsSmartAccount.handleOps(userOps, r, vs);
        assertEq(dfnsSmartAccount.getNonce(), 1);
    }
}
