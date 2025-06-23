// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {DfnsSmartAccount} from "../src/DfnsSmartAccount.sol";

import {UserOperation, DfnsTestUtils} from "./utils/DfnsTestUtils.sol";

error InvalidSignature();
error InvalidTarget();
error OutOfBounds();

contract DfnsSmartAccountTest is Test {
    DfnsSmartAccount public dfnsSmartAccount;

    address public constant RANDOM_DESTINATION = 0x09D450BDD08B7eA3E04BCAec52A60124ad386Fca;
    address public sponsor;
    address public sponsoree;
    uint256 public sponsoreePrivateKey;

    bytes private encodedUserOperations;
    uint256 private r;
    uint256 private vs;

    function setUp() public {
        // Holesky chain id
        vm.chainId(17000);
        (sponsoree, sponsoreePrivateKey) = makeAddrAndKey("sponsoree");

        address contractAddress = 0xbD77a32E628e69D8B168d3813F019E51D787b569;

        deployCodeTo("DfnsSmartAccount.sol", contractAddress);

        vm.deal(sponsoree, 100 ether);
        vm.signAndAttachDelegation(contractAddress, sponsoreePrivateKey);

        dfnsSmartAccount = DfnsSmartAccount(payable(sponsoree));
        sponsor = address(this);

        generateTestVector();
    }

    function generateTestVector() internal {
        UserOperation[] memory userOperations = new UserOperation[](1);
        userOperations[0] = UserOperation({to: RANDOM_DESTINATION, value: 1, data: "0x12345678"});

        encodedUserOperations = DfnsTestUtils.encodeOperations(userOperations);

        uint256 nonce = dfnsSmartAccount.getNonce();
        (r, vs) =
            DfnsTestUtils.generateSignature(vm, encodedUserOperations, nonce, sponsoree, sponsoreePrivateKey, sponsor);
    }

    function test_handleOps() public {
        assertEq(dfnsSmartAccount.getNonce(), 0);
        dfnsSmartAccount.handleOps(encodedUserOperations, r, vs);
        assertEq(dfnsSmartAccount.getNonce(), 1);
    }

    function test_handleOpsWrongSponsor() public {
        assertEq(dfnsSmartAccount.getNonce(), 0);
        address otherSponsor = address(0xBEEF);
        vm.deal(otherSponsor, 100 ether);
        vm.prank(otherSponsor);
        vm.expectRevert(InvalidSignature.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, r, vs);
        assertEq(dfnsSmartAccount.getNonce(), 0);
    }

    function test_handleOpsWrongSignature() public {
        assertEq(dfnsSmartAccount.getNonce(), 0);
        vm.expectRevert(InvalidSignature.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, r, vs + 1);
        assertEq(dfnsSmartAccount.getNonce(), 0);
    }

    function test_handleOpsReplayProtection() public {
        assertEq(dfnsSmartAccount.getNonce(), 0);
        dfnsSmartAccount.handleOps(encodedUserOperations, r, vs);
        vm.expectRevert(InvalidSignature.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, r, vs);
        assertEq(dfnsSmartAccount.getNonce(), 1);
    }

    function test_handleOpsWrongTarget() public {
        UserOperation[] memory userOperations = new UserOperation[](1);
        userOperations[0] = UserOperation({to: address(0), value: 1, data: new bytes(0)});

        encodedUserOperations = DfnsTestUtils.encodeOperations(userOperations);

        uint256 nonce = dfnsSmartAccount.getNonce();
        (r, vs) =
            DfnsTestUtils.generateSignature(vm, encodedUserOperations, nonce, sponsoree, sponsoreePrivateKey, sponsor);

        vm.expectRevert(InvalidTarget.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, r, vs);
    }

    function test_handleOpsOutOfBounds() public {
        encodedUserOperations = abi.encodePacked(
            RANDOM_DESTINATION,
            uint256(1), // value
            uint256(65536), // out of bounds length
            "0x12345678"
        );

        uint256 nonce = dfnsSmartAccount.getNonce();
        (r, vs) =
            DfnsTestUtils.generateSignature(vm, encodedUserOperations, nonce, sponsoree, sponsoreePrivateKey, sponsor);

        vm.expectRevert(OutOfBounds.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, r, vs);
    }

    function test_sponsoreeCanReceiveEth() public {
        uint256 initialBalance = sponsoree.balance;
        payable(sponsoree).transfer(1 ether);
        assertEq(sponsoree.balance, initialBalance + 1 ether);
    }
}
