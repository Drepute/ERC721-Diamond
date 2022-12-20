// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Somesh Chaturvedi <somesh@drepute.xyz>, Twitter/Github: @someshc8i
/******************************************************************************/

import { LibERC721 } from  "../../../libraries/erc721/LibERC721.sol";

contract BurnFacet {
    using LibERC721 for LibERC721.Layout;
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);


    /*//////////////////////////////////////////////////////////////
                        ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _burn(uint256 id) internal virtual {
        LibERC721.Layout storage s = LibERC721.layout();
        address owner = s._ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            s._balanceOf[owner]--;
        }

        delete s._ownerOf[id];

        delete s.getApproved[id];

        emit Transfer(owner, address(0), id);
    }
}