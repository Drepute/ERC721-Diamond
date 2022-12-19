// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibERC721 {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    struct Layout {
    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

        string name;
        string symbol;
    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

        mapping(uint256 => address) _ownerOf;
        mapping(address => uint256) _balanceOf;
    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

        mapping(uint256 => address) getApproved;
        mapping(address => mapping(address => bool)) isApprovedForAll;


    // /*//////////////////////////////////////////////////////////////
    //                      ERC721 ENUMERABLE STORAGE
    // //////////////////////////////////////////////////////////////*/
    //     uint256 totalSupply;


    // /*//////////////////////////////////////////////////////////////
    //                      ERC721 URI STORAGE
    // //////////////////////////////////////////////////////////////*/

    //     mapping(uint256 => bytes32) uri;

    // /*//////////////////////////////////////////////////////////////
    //                      ERC721 PRICE STORAGE
    // //////////////////////////////////////////////////////////////*/

    //     mapping(uint8 => uint256) price;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("ERC721.contracts.storage.ERC721");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
