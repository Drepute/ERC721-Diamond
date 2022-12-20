// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Somesh Chaturvedi <somesh@drepute.xyz>, Twitter/Github: @someshc8i
/******************************************************************************/

import { LibERC721 } from  "../../libraries/erc721/LibERC721.sol";
import {ERC721TokenReceiver} from "../../../lib/solmate/src/tokens/ERC721.sol";
import { LibDiamond } from  "../../libraries/LibDiamond.sol";

contract MetadataFacet {
    using LibERC721 for LibERC721.Layout;
    
    /*//////////////////////////////////////////////////////////////
                         ERC721 METADATA LOGIC
    //////////////////////////////////////////////////////////////*/
    function name() external view virtual returns (string memory) {
        LibERC721.Layout storage s = LibERC721.layout();
        return s.name;
    }

    function symbol() external view virtual returns (string memory) {
        LibERC721.Layout storage s = LibERC721.layout();
        return s.symbol;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC721 OWNER/BALANCE LOGIC
    //////////////////////////////////////////////////////////////*/

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        LibERC721.Layout storage s = LibERC721.layout();
        require((owner = s._ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        LibERC721.Layout storage s = LibERC721.layout();
        require(owner != address(0), "ZERO_ADDRESS");

        return s._balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL LOGIC
    //////////////////////////////////////////////////////////////*/
    function getApproved(uint256 id) public view virtual returns (address owner) {
        LibERC721.Layout storage s = LibERC721.layout();
        owner = s.getApproved[id];
    }


    function isApprovedForAll(address owner, address spender) public view virtual returns (bool) {
        LibERC721.Layout storage s = LibERC721.layout();
        return s.isApprovedForAll[owner][spender];
    }
}