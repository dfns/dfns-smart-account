// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.29;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
/**
 * @title DfnsSmartAccount - This contract support batch execution of transactions.
 * The only storage is a nonce bitmap to prevent replay attacks, allowing nonces to be consumed out of order.
 * The contract is intended to be used with EIP-7702 where EOA delegates to this contract.
 */

contract DfnsSmartAccount is IERC1155Receiver, IERC721Receiver, IERC1271 {
    using ECDSA for bytes32;

    struct Storage {
        uint256[] nonces;
    }

    // keccak256("DfnsSmartAccount") & (~0xff)
    bytes32 private constant _STORAGE = 0x10ee8db8a0021e326896fcf9b44ce61becefe5f52e3dfd0bb294aee9b73bc000;
    // keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    bytes32 private constant _DOMAIN_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    // keccak256("HandleOps(bytes32 data,uint256 nonce,address sponsor)")
    bytes32 private constant _HANDLEOPS_TYPEHASH = 0x4d45d6aca00518e5f826ef561e48d49260fb16644409228c5e739cb8f3c7c68e;
    // Maximum number the nonce array can grow by in a single call.
    uint256 private constant _MAX_NONCE_GROWTH = 10;

    error InvalidSignature();
    error InvalidTarget();
    error OutOfBounds();
    error NonceAlreadyUsed();
    error NonceTooFar();

    /**
     * @dev Sends multiple transactions with signature validation and reverts all if one fails.
     * @param userOps Encoded User Ops.
     * @param nonce Unique nonce; bit `nonce % 256` of `nonces[nonce / 256]` must be unset and is set on success.
     * @param r The r part of the signature.
     * @param vs The v and s part of the signature.
     */
    function handleOps(bytes memory userOps, uint256 nonce, uint256 r, uint256 vs) public payable {
        // Calculate the hash of transactions data and nonce for signature verification
        bytes32 domainSeparator = keccak256(abi.encode(_DOMAIN_TYPEHASH, block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(_HANDLEOPS_TYPEHASH, keccak256(userOps), nonce, msg.sender));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        // Verify the signature
        require(address(this) == digest.recover(bytes32(r), bytes32(vs)), InvalidSignature());

        _useNonce(nonce);

        /* solhint-disable no-inline-assembly */
        assembly ("memory-safe") {
            let length := mload(userOps)
            let end := add(length, 0x20)
            let i := 0x20
            for {} lt(i, end) {} {
                let to := shr(0x60, mload(add(userOps, i)))
                if iszero(to) {
                    // Revert with InvalidTarget() custom error selector
                    mstore(0x00, 0x82d5d76a) // selector for InvalidTarget()
                    revert(0x1c, 0x04)
                }
                let value := mload(add(userOps, add(i, 0x14)))
                let dataLength := mload(add(userOps, add(i, 0x34)))

                let opEnd := add(i, add(0x54, dataLength))
                if gt(opEnd, end) {
                    // Revert with OutOfBounds() custom error selector
                    mstore(0x00, 0xb4120f14) // selector for OutOfBounds()
                    revert(0x1c, 0x04)
                }

                let data := add(userOps, add(i, 0x54))
                let success := call(gas(), to, value, data, dataLength, 0, 0)

                if eq(success, 0) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
                i := opEnd
            }
        }
        /* solhint-enable no-inline-assembly */
    }

    /**
     * @dev ERC-1271: Validates if the provided signature is valid for the given hash.
     * @param hash The hash of the signed data.
     * @param signature The signature to validate.
     * @return magicValue The ERC-1271 magic value (0x1626ba7e) if the signature is valid, 0x00000000 otherwise.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        return address(this) == hash.recover(signature) ? this.isValidSignature.selector : bytes4(0);
    }

    /**
     * @dev Marks `nonce` as used. Reverts if it was already used or if the array would need
     * to grow by more than `_MAX_NONCE_GROWTH` words to fit the nonce.
     */
    function _useNonce(uint256 nonce) internal {
        Storage storage $ = _storage();
        uint256 positionInArray = nonce >> 8;
        uint256 mask = 1 << (nonce & 0xff);
        uint256 length = $.nonces.length;
        if (length <= positionInArray) {
            require(positionInArray < length + _MAX_NONCE_GROWTH, NonceTooFar());
            // Bump array length in a single SSTORE; element slots default to zero.
            assembly ("memory-safe") {
                sstore(_STORAGE, add(positionInArray, 1))
            }
        }
        uint256 word = $.nonces[positionInArray];
        require(word & mask == 0, NonceAlreadyUsed());
        $.nonces[positionInArray] = word | mask;
    }

    function _storage() private pure returns (Storage storage $) {
        assembly ("memory-safe") {
            $.slot := _STORAGE
        }
    }

    function isNonceUsed(uint256 nonce) external view returns (bool) {
        Storage storage $ = _storage();
        uint256 positionInArray = nonce >> 8;
        if (positionInArray >= $.nonces.length) return false;
        return ($.nonces[positionInArray] & (1 << (nonce & 0xff))) != 0;
    }

    /**
     * @dev Returns the next nonce to use, found in the last entry of the array.
     * If that entry is fully consumed, returns the first nonce of the next (not-yet-allocated) word.
     */
    function nextNonce() external view returns (uint256) {
        Storage storage $ = _storage();
        uint256 length = $.nonces.length;
        if (length == 0) return 0;
        uint256 lastIndex = length - 1;
        uint256 word = $.nonces[lastIndex];
        for (uint256 b = 0; b < 256; b++) {
            if (word & (1 << b) == 0) return (lastIndex << 8) | b;
        }
        return length << 8;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == 0x01ffc9a7; // IERC165
    }

    receive() external payable {}
}
