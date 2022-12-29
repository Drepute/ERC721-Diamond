// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Somesh Chaturvedi <somesh@drepute.xyz>, Twitter/Github: @someshc8i
/******************************************************************************/

import { MintFacet } from  "../facets/erc721/mint/MintFacet.sol";

contract MintFacetMock is MintFacet {
    /*//////////////////////////////////////////////////////////////
                        ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 tokenId) public virtual {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public virtual {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        _safeMint(to, tokenId, data);
    }
}