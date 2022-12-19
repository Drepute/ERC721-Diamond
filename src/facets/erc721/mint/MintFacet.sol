// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Somesh Chaturvedi <somesh@drepute.xyz>, Twitter/Github: @someshc8i
/******************************************************************************/

import { LibERC721 } from  "../../../libraries/LibERC721.sol";

contract MintFacet {
    using LibERC721 for LibERC721.Layout;
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        LibERC721.Layout storage s = LibERC721.layout();
        require(to != address(0), "INVALID_RECIPIENT");

        require(s._ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            s._balanceOf[to]++;
        }

        s._ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}