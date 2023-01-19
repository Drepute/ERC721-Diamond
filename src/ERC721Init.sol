// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { LibERC721 } from "./libraries/erc721/LibERC721.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IERC173 } from "./interfaces/IERC173.sol";
import { IERC165 } from "./interfaces/IERC165.sol";

contract ERC721Init {
    using LibERC721 for LibERC721.Layout;

    function init(string memory name_, string memory symbol_) external {
        LibERC721.Layout storage s = LibERC721.layout();
        s.name = name_;
        s.symbol = symbol_;
    }
}
