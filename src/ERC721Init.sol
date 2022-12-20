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

    /*//////////////////////////////////////////////////////////////
                         ERC721 INITIALIZATION MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }


    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializerERC721A() {
        LibERC721.Layout storage s = LibERC721.layout();
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            s.initializing
                ? _isConstructor()
                : !s.initialized,
            'ERC721A__Initializable: contract is already initialized'
        );

        bool isTopLevelCall = !s.initializing;
        if (isTopLevelCall) {
            s.initializing = true;
            s.initialized = true;
        }

        _;

        if (isTopLevelCall) {
            s.initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializingERC721A() {
        LibERC721.Layout storage s = LibERC721.layout();
        require(
            s.initializing,
            'ERC721A__Initializable: contract is not initializing'
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    function ERC721__init(string memory name_, string memory symbol_) external initializerERC721A {
         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        __ERC721A_init(name_, symbol_);
        ds.supportedInterfaces[bytes4(bytes('0x7aa5391d'))] = true;
        
    }

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        LibERC721.Layout storage s = LibERC721.layout();
        s.name = name_;
        s.symbol = symbol_;
    }
}
