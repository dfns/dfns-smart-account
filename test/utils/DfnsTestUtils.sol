// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Vm} from "forge-std/Vm.sol";

struct UserOperation {
    address to; // 20 bytes
    uint256 value; // 32 bytes
    bytes data; // variable length
}

library DfnsTestUtils {
    bytes32 private constant _STORAGE = 0x10ee8db8a0021e326896fcf9b44ce61becefe5f52e3dfd0bb294aee9b73bc000;
    bytes32 private constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _NAME_HASH = 0x10ee8db8a0021e326896fcf9b44ce61becefe5f52e3dfd0bb294aee9b73bc0d1;
    bytes32 private constant _VERSION_HASH = 0xad7c5bef027816a800da1736444fb58a807ef4c9603b7848673f7e3a68eb14a5;
    bytes32 private constant _HANDLEOPS_TYPEHASH = 0x4d45d6aca00518e5f826ef561e48d49260fb16644409228c5e739cb8f3c7c68e;

    // Signature malleability protection constants
    uint256 private constant CURVE_ORDER = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
    uint256 private constant HALF_CURVE_ORDER = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    function encodeOperations(UserOperation[] memory operations) internal pure returns (bytes memory) {
        bytes memory encoded;

        for (uint256 i = 0; i < operations.length; i++) {
            encoded = abi.encodePacked(
                encoded,
                operations[i].to, // 20 bytes
                operations[i].value, // 32 bytes
                operations[i].data.length, // 32 bytes
                operations[i].data // variable length
            );
        }

        return encoded;
    }

    function computeDigest(bytes memory userOps, uint256 nonce, address contractAddress, address sponsor)
        internal
        view
        returns (bytes32 digest)
    {
        bytes32 domainSeparator =
            keccak256(abi.encode(_DOMAIN_TYPEHASH, _NAME_HASH, _VERSION_HASH, block.chainid, contractAddress));
        bytes32 structHash = keccak256(abi.encode(_HANDLEOPS_TYPEHASH, keccak256(userOps), nonce, sponsor));
        digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function generateSignature(
        Vm vm,
        bytes memory userOps,
        uint256 nonce,
        address contractAddress,
        uint256 eoaOwnerPrivateKey,
        address sponsor
    ) internal view returns (uint256 r, uint256 vs) {
        // In EIP-7702 context, the contract calculates digest using EOA address as address(this)
        bytes32 digest = computeDigest(userOps, nonce, contractAddress, sponsor);

        // Sign with the EOA's private key
        (uint8 v, bytes32 rBytes, bytes32 s) = vm.sign(eoaOwnerPrivateKey, digest);

        // Apply malleability protection - ensure s is in lower half of curve order
        uint256 sValue = uint256(s);
        if (sValue > HALF_CURVE_ORDER) {
            sValue = CURVE_ORDER - sValue;
            // When we flip s, we also need to flip v
            v = v == 27 ? 28 : 27;
        }

        // Convert to the vs format used by the contract
        // The vs format: high bit indicates v parity, remaining 255 bits are s
        r = uint256(rBytes);

        // Ensure s fits in 255 bits (clear high bit) and set v bit
        sValue = sValue & 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        vs = (v == 27 ? 0 : uint256(1 << 255)) | sValue;
    }
}
