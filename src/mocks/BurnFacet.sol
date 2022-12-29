// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Somesh Chaturvedi <somesh@drepute.xyz>, Twitter/Github: @someshc8i
/******************************************************************************/

import { BurnFacet } from  "../facets/erc721/burn/BurnFacet.sol";

contract BurnFacetMock is BurnFacet {
    /*//////////////////////////////////////////////////////////////
                        ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }
}