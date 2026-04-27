// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {DfnsSmartAccount} from "../src/DfnsSmartAccount.sol";

import {UserOperation, DfnsTestUtils} from "./utils/DfnsTestUtils.sol";

error InvalidSignature();
error InvalidTarget();
error OutOfBounds();
error NonceAlreadyUsed();
error NonceTooFar();

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

        (r, vs) = DfnsTestUtils.generateSignature(vm, encodedUserOperations, 0, sponsoree, sponsoreePrivateKey, sponsor);
    }

    function test_handleOps() public {
        assertFalse(dfnsSmartAccount.isNonceUsed(0));
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);
        assertTrue(dfnsSmartAccount.isNonceUsed(0));
    }

    function test_handleOpsBatch() public {
        address secondDestination = address(0xBEEF);
        vm.deal(secondDestination, 0);

        UserOperation[] memory userOperations = new UserOperation[](2);
        userOperations[0] = UserOperation({to: RANDOM_DESTINATION, value: 1, data: ""});
        userOperations[1] = UserOperation({to: secondDestination, value: 2, data: "0xdeadbeef"});

        encodedUserOperations = DfnsTestUtils.encodeOperations(userOperations);

        (r, vs) = DfnsTestUtils.generateSignature(vm, encodedUserOperations, 0, sponsoree, sponsoreePrivateKey, sponsor);

        uint256 randomDestBalanceBefore = RANDOM_DESTINATION.balance;

        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);

        assertEq(RANDOM_DESTINATION.balance, randomDestBalanceBefore + 1);
        assertEq(secondDestination.balance, 2);
        assertTrue(dfnsSmartAccount.isNonceUsed(0));
    }

    function test_handleOpsWrongSponsor() public {
        address otherSponsor = address(0xBEEF);
        vm.deal(otherSponsor, 100 ether);
        vm.prank(otherSponsor);
        vm.expectRevert(InvalidSignature.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);
        assertFalse(dfnsSmartAccount.isNonceUsed(0));
    }

    function test_handleOpsWrongSignature() public {
        vm.expectRevert(InvalidSignature.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs + 1);
        assertFalse(dfnsSmartAccount.isNonceUsed(0));
    }

    function test_handleOpsReplayProtection() public {
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);
        vm.expectRevert(NonceAlreadyUsed.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);
        assertTrue(dfnsSmartAccount.isNonceUsed(0));
    }

    function test_handleOpsOutOfOrderNonces() public {
        // Use nonce 5 first (bit 5 of word 0).
        (uint256 r5, uint256 vs5) =
            DfnsTestUtils.generateSignature(vm, encodedUserOperations, 5, sponsoree, sponsoreePrivateKey, sponsor);
        dfnsSmartAccount.handleOps(encodedUserOperations, 5, r5, vs5);
        assertTrue(dfnsSmartAccount.isNonceUsed(5));
        assertFalse(dfnsSmartAccount.isNonceUsed(0));

        // Then use nonce 0 — should still work.
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);
        assertTrue(dfnsSmartAccount.isNonceUsed(0));
    }

    function test_handleOpsCrossWordNonce() public {
        // Nonce 256 lives in word 1, bit 0 — array must grow from length 0 to 2.
        uint256 nonce = 256;
        (uint256 rN, uint256 vsN) =
            DfnsTestUtils.generateSignature(vm, encodedUserOperations, nonce, sponsoree, sponsoreePrivateKey, sponsor);
        dfnsSmartAccount.handleOps(encodedUserOperations, nonce, rN, vsN);
        assertTrue(dfnsSmartAccount.isNonceUsed(nonce));
    }

    function test_handleOpsNonceTooFar() public {
        // Growth limit is 10 words; from length 0, word 10 (nonce 2560) is one past the limit.
        uint256 nonce = 256 * 10;
        (uint256 rN, uint256 vsN) =
            DfnsTestUtils.generateSignature(vm, encodedUserOperations, nonce, sponsoree, sponsoreePrivateKey, sponsor);
        vm.expectRevert(NonceTooFar.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, nonce, rN, vsN);
    }

    function test_handleOpsWrongTarget() public {
        UserOperation[] memory userOperations = new UserOperation[](1);
        userOperations[0] = UserOperation({to: address(0), value: 1, data: new bytes(0)});

        encodedUserOperations = DfnsTestUtils.encodeOperations(userOperations);

        (r, vs) = DfnsTestUtils.generateSignature(vm, encodedUserOperations, 0, sponsoree, sponsoreePrivateKey, sponsor);

        vm.expectRevert(InvalidTarget.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);
    }

    function test_handleOpsOutOfBounds() public {
        encodedUserOperations = abi.encodePacked(
            RANDOM_DESTINATION,
            uint256(1), // value
            uint256(65536), // out of bounds length
            "0x12345678"
        );

        (r, vs) = DfnsTestUtils.generateSignature(vm, encodedUserOperations, 0, sponsoree, sponsoreePrivateKey, sponsor);

        vm.expectRevert(OutOfBounds.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);
    }

    function test_handleOpsOutOfBoundsEdgeCase() public {
        // Declare dataLength=10 but include 0 actual data bytes.
        // Total encoded: 20 + 32 + 32 = 84 bytes (0x54), but claims 10 extra.
        // Old bounds check missed this because it was 0x34 bytes too loose.
        encodedUserOperations = abi.encodePacked(
            RANDOM_DESTINATION,
            uint256(1), // value
            uint256(10) // claims 10 bytes of data, but none follow
        );

        (r, vs) = DfnsTestUtils.generateSignature(vm, encodedUserOperations, 0, sponsoree, sponsoreePrivateKey, sponsor);

        vm.expectRevert(OutOfBounds.selector);
        dfnsSmartAccount.handleOps(encodedUserOperations, 0, r, vs);
    }

    function test_sponsoreeCanReceiveEth() public {
        uint256 initialBalance = sponsoree.balance;
        payable(sponsoree).transfer(1 ether);
        assertEq(sponsoree.balance, initialBalance + 1 ether);
    }

    function test_isValidSignatureSuccess() public view {
        bytes32 hash = keccak256("valid");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sponsoreePrivateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes4 magic = dfnsSmartAccount.isValidSignature(hash, signature);
        assertEq(magic, bytes4(0x1626ba7e));
    }

    function test_isValidSignatureInvalidLength() public {
        bytes32 hash = keccak256("valid");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sponsoreePrivateKey, hash);

        // 32 bytes (first 32 bytes of real signature)
        bytes memory sig32 = abi.encodePacked(r);
        vm.expectRevert();
        dfnsSmartAccount.isValidSignature(hash, sig32);

        // 64 bytes (first 64 bytes of real signature)
        bytes memory sig64 = abi.encodePacked(r, s);
        vm.expectRevert();
        dfnsSmartAccount.isValidSignature(hash, sig64);

        // 96 bytes (real signature padded to 96 bytes)
        bytes memory sig96 = abi.encodePacked(r, s, v, bytes31(0));
        vm.expectRevert();
        dfnsSmartAccount.isValidSignature(hash, sig96);
    }

    function test_isValidSignatureFail() public view {
        bytes32 hash = keccak256("invalid");
        bytes memory signature = abi.encodePacked(bytes32(uint256(1)), bytes32(uint256(2)), uint8(27));
        bytes4 magic = dfnsSmartAccount.isValidSignature(hash, signature);
        assertEq(magic, bytes4(0));
    }
}
