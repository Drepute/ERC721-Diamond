// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Somesh Chaturvedi <somesh@drepute.xyz>, Twitter/Github: @someshc8i
/******************************************************************************/

import { LibERC721 } from  "../../../libraries/erc721/LibERC721.sol";

contract ApproveFacet {
    using LibERC721 for LibERC721.Layout;
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        LibERC721.Layout storage s = LibERC721.layout();
        address owner = s._ownerOf[id];

        require(msg.sender == owner || s.isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        s.getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        LibERC721.Layout storage s = LibERC721.layout();
        s.isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

}