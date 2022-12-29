// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {DSTestPlus} from "../lib/solmate/src/test/utils/DSTestPlus.sol";

import {DSInvariantTest} from "../lib/solmate/src/test/utils/DSInvariantTest.sol";

import {ERC721, DiamondArgs} from "../src/ERC721.sol";
import {ERC721Init} from "../src/ERC721Init.sol";

import {MetadataFacet} from "../src/facets/erc721/MetadataFacet.sol";
import {MintFacetMock} from "../src/mocks/MintFacet.sol";
import {BurnFacetMock} from "../src/mocks/BurnFacet.sol";
import {ApproveFacetMock} from "../src/mocks/ApproveFacet.sol";
import {TransferFacetMock} from "../src/mocks/TransferFacet.sol";

import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";

import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamond} from "../src/interfaces/IDiamond.sol";

import {ERC721TokenReceiver} from "../lib/solmate/src/tokens/ERC721.sol";

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        revert(
            string(
                abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)
            )
        );
    }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

contract ERC721DiamondTest is DSTestPlus {
    ERC721 token;
    MetadataFacet token__metadata;
    MintFacetMock token__mint;
    BurnFacetMock token__burn;
    ApproveFacetMock token__approve;
    TransferFacetMock token__transfer;

    function _deploy(string memory _name, string memory _symbol) public returns(address) {
        MetadataFacet metadata = new MetadataFacet();
        emit log_address(address(metadata));
        MintFacetMock mint = new MintFacetMock();
        BurnFacetMock burn = new BurnFacetMock();
        ApproveFacetMock approve = new ApproveFacetMock();
        TransferFacetMock transfer = new TransferFacetMock();
        DiamondCutFacet cut = new DiamondCutFacet();
        DiamondLoupeFacet loupe = new DiamondLoupeFacet();
        ERC721Init init = new ERC721Init();

        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](7);
        _diamondCut[0] = IDiamond.FacetCut(
            address(metadata),
            IDiamond.FacetCutAction.Add,
            Selector.selectors(metadata)
        );
        _diamondCut[1] = IDiamond.FacetCut(
            address(mint),
            IDiamond.FacetCutAction.Add,
            Selector.selectors(mint)
        );
        _diamondCut[2] = IDiamond.FacetCut(
            address(burn),
            IDiamond.FacetCutAction.Add,
            Selector.selectors(burn)
        );
        _diamondCut[3] = IDiamond.FacetCut(
            address(approve),
            IDiamond.FacetCutAction.Add,
            Selector.selectors(approve)
        );
        _diamondCut[4] = IDiamond.FacetCut(
            address(transfer),
            IDiamond.FacetCutAction.Add,
            Selector.selectors(transfer)
        ); 
        _diamondCut[5] = IDiamond.FacetCut(
            address(cut),
            IDiamond.FacetCutAction.Add,
            Selector.selectors(cut)
        );
        _diamondCut[6] = IDiamond.FacetCut(
            address(loupe),
            IDiamond.FacetCutAction.Add,
            Selector.selectors(loupe)
        );


        DiamondArgs memory _args = DiamondArgs({
            owner: address(this),
            init: address(init),
            initCalldata: abi.encodeWithSelector(bytes4(0x5b9c7303), _name, _symbol)}
        );
        token = new ERC721(_diamondCut, _args);
        return address(token);
    }

    function setUp() public {
        address tokenAddress = _deploy("Token", "TKN");
        token = ERC721(payable(tokenAddress));
        token__metadata = MetadataFacet(tokenAddress);
        token__mint = MintFacetMock(tokenAddress);
        token__burn = BurnFacetMock(tokenAddress);
        token__approve = ApproveFacetMock(tokenAddress);
        token__transfer = TransferFacetMock(tokenAddress);
    }

    function invariantMetadata() public {
        assertEq(token__metadata.name(), "Token");
        assertEq(token__metadata.symbol(), "TKN");
    }

    function testMint() public {
        token__mint.mint(address(0xBEEF), 1337);

        assertEq(token__metadata.balanceOf(address(0xBEEF)), 1);
        assertEq(token__metadata.ownerOf(1337), address(0xBEEF));
    }

    function testBurn() public {
        token__mint.mint(address(0xBEEF), 1337);
        token__burn.burn(1337);

        assertEq(token__metadata.balanceOf(address(0xBEEF)), 0);

        hevm.expectRevert("NOT_MINTED");
        token__metadata.ownerOf(1337);
    }

    function testApprove() public {
        token__mint.mint(address(this), 1337);

        token__approve.approve(address(0xBEEF), 1337);

        assertEq(token__metadata.getApproved(1337), address(0xBEEF));
    }

    function testApproveBurn() public {
        token__mint.mint(address(this), 1337);

        token__approve.approve(address(0xBEEF), 1337);

        token__burn.burn(1337);

        assertEq(token__metadata.balanceOf(address(this)), 0);
        assertEq(token__metadata.getApproved(1337), address(0));

        hevm.expectRevert("NOT_MINTED");
        token__metadata.ownerOf(1337);
    }

    function testApproveAll() public {
        token__approve.setApprovalForAll(address(0xBEEF), true);

        assertTrue(token__metadata.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token__mint.mint(from, 1337);

        hevm.prank(from);
        token__approve.approve(address(this), 1337);

        token__transfer.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token__metadata.getApproved(1337), address(0));
        assertEq(token__metadata.ownerOf(1337), address(0xBEEF));
        assertEq(token__metadata.balanceOf(address(0xBEEF)), 1);
        assertEq(token__metadata.balanceOf(from), 0);
    }

    function testTransferFromSelf() public {
        token__mint.mint(address(this), 1337);

        token__transfer.transferFrom(address(this), address(0xBEEF), 1337);

        assertEq(token__metadata.getApproved(1337), address(0));
        assertEq(token__metadata.ownerOf(1337), address(0xBEEF));
        assertEq(token__metadata.balanceOf(address(0xBEEF)), 1);
        assertEq(token__metadata.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll() public {
        address from = address(0xABCD);

        token__mint.mint(from, 1337);

        hevm.prank(from);
        token__approve.setApprovalForAll(address(this), true);

        token__transfer.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token__metadata.getApproved(1337), address(0));
        assertEq(token__metadata.ownerOf(1337), address(0xBEEF));
        assertEq(token__metadata.balanceOf(address(0xBEEF)), 1);
        assertEq(token__metadata.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token__mint.mint(from, 1337);

        hevm.prank(from);
        token__approve.setApprovalForAll(address(this), true);

        token__transfer.safeTransferFrom(from, address(0xBEEF), 1337);

        assertEq(token__metadata.getApproved(1337), address(0));
        assertEq(token__metadata.ownerOf(1337), address(0xBEEF));
        assertEq(token__metadata.balanceOf(address(0xBEEF)), 1);
        assertEq(token__metadata.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token__mint.mint(from, 1337);

        hevm.prank(from);
        token__approve.setApprovalForAll(address(this), true);

        token__transfer.safeTransferFrom(from, address(recipient), 1337);

        assertEq(token__metadata.getApproved(1337), address(0));
        assertEq(token__metadata.ownerOf(1337), address(recipient));
        assertEq(token__metadata.balanceOf(address(recipient)), 1);
        assertEq(token__metadata.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertBytesEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token__mint.mint(from, 1337);

        hevm.prank(from);
        token__approve.setApprovalForAll(address(this), true);

        token__transfer.safeTransferFrom(from, address(recipient), 1337, "testing 123");

        assertEq(token__metadata.getApproved(1337), address(0));
        assertEq(token__metadata.ownerOf(1337), address(recipient));
        assertEq(token__metadata.balanceOf(address(recipient)), 1);
        assertEq(token__metadata.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertBytesEq(recipient.data(), "testing 123");
    }

    function testSafeMintToEOA() public {
        token__mint.safeMint(address(0xBEEF), 1337);

        assertEq(token__metadata.ownerOf(1337), address(address(0xBEEF)));
        assertEq(token__metadata.balanceOf(address(address(0xBEEF))), 1);
    }

    function testSafeMintToERC721Recipient() public {
        ERC721Recipient to = new ERC721Recipient();

        token__mint.safeMint(address(to), 1337);

        assertEq(token__metadata.ownerOf(1337), address(to));
        assertEq(token__metadata.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertBytesEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData() public {
        ERC721Recipient to = new ERC721Recipient();

        token__mint.safeMint(address(to), 1337, "testing 123");

        assertEq(token__metadata.ownerOf(1337), address(to));
        assertEq(token__metadata.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertBytesEq(to.data(), "testing 123");
    }

    function testFailMintToZero() public {
        token__mint.mint(address(0), 1337);
    }

    function testFailDoubleMint() public {
        token__mint.mint(address(0xBEEF), 1337);
        token__mint.mint(address(0xBEEF), 1337);
    }

    function testFailBurnUnMinted() public {
        token__burn.burn(1337);
    }

    function testFailDoubleBurn() public {
        token__mint.mint(address(0xBEEF), 1337);

        token__burn.burn(1337);
        token__burn.burn(1337);
    }

    function testFailApproveUnMinted() public {
        token__approve.approve(address(0xBEEF), 1337);
    }

    function testFailApproveUnAuthorized() public {
        token__mint.mint(address(0xCAFE), 1337);

        token__approve.approve(address(0xBEEF), 1337);
    }

    function testFailTransferFromUnOwned() public {
        token__transfer.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailTransferFromWrongFrom() public {
        token__mint.mint(address(0xCAFE), 1337);

        token__transfer.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailTransferFromToZero() public {
        token__mint.mint(address(this), 1337);

        token__transfer.transferFrom(address(this), address(0), 1337);
    }

    function testFailTransferFromNotOwner() public {
        token__mint.mint(address(0xFEED), 1337);

        token__transfer.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailSafeTransferFromToNonERC721Recipient() public {
        token__mint.mint(address(this), 1337);

        token__transfer.safeTransferFrom(
            address(this),
            address(new NonERC721Recipient()),
            1337
        );
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData() public {
        token__mint.mint(address(this), 1337);

        token__transfer.safeTransferFrom(
            address(this),
            address(new NonERC721Recipient()),
            1337,
            "testing 123"
        );
    }

    function testFailSafeTransferFromToRevertingERC721Recipient() public {
        token__mint.mint(address(this), 1337);

        token__transfer.safeTransferFrom(
            address(this),
            address(new RevertingERC721Recipient()),
            1337
        );
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData()
        public
    {
        token__mint.mint(address(this), 1337);

        token__transfer.safeTransferFrom(
            address(this),
            address(new RevertingERC721Recipient()),
            1337,
            "testing 123"
        );
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData()
        public
    {
        token__mint.mint(address(this), 1337);

        token__transfer.safeTransferFrom(
            address(this),
            address(new WrongReturnDataERC721Recipient()),
            1337
        );
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData()
        public
    {
        token__mint.mint(address(this), 1337);

        token__transfer.safeTransferFrom(
            address(this),
            address(new WrongReturnDataERC721Recipient()),
            1337,
            "testing 123"
        );
    }

    function testFailSafeMintToNonERC721Recipient() public {
        token__mint.safeMint(address(new NonERC721Recipient()), 1337);
    }

    function testFailSafeMintToNonERC721RecipientWithData() public {
        token__mint.safeMint(address(new NonERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeMintToRevertingERC721Recipient() public {
        token__mint.safeMint(address(new RevertingERC721Recipient()), 1337);
    }

    function testFailSafeMintToRevertingERC721RecipientWithData() public {
        token__mint.safeMint(
            address(new RevertingERC721Recipient()),
            1337,
            "testing 123"
        );
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnData() public {
        token__mint.safeMint(address(new WrongReturnDataERC721Recipient()), 1337);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData()
        public
    {
        token__mint.safeMint(
            address(new WrongReturnDataERC721Recipient()),
            1337,
            "testing 123"
        );
    }

    function testFailBalanceOfZeroAddress() public view {
        token__metadata.balanceOf(address(0));
    }

    function testFailOwnerOfUnminted() public view {
        token__metadata.ownerOf(1337);
    }

    // function testMetadata(string memory name, string memory symbol) public {
    //     ERC721 tkn = new ERC721(name, symbol);

    //     assertEq(tkn.name(), name);
    //     assertEq(tkn.symbol(), symbol);
    // }

    function testMint(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token__mint.mint(to, id);

        assertEq(token__metadata.balanceOf(to), 1);
        assertEq(token__metadata.ownerOf(id), to);
    }

    function testBurn(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token__mint.mint(to, id);
        token__burn.burn(id);

        assertEq(token__metadata.balanceOf(to), 0);

        hevm.expectRevert("NOT_MINTED");
        token__metadata.ownerOf(id);
    }

    function testApprove(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token__mint.mint(address(this), id);

        token__approve.approve(to, id);

        assertEq(token__metadata.getApproved(id), to);
    }

    function testApproveBurn(address to, uint256 id) public {
        token__mint.mint(address(this), id);

        token__approve.approve(address(to), id);

        token__burn.burn(id);

        assertEq(token__metadata.balanceOf(address(this)), 0);
        assertEq(token__metadata.getApproved(id), address(0));

        hevm.expectRevert("NOT_MINTED");
        token__metadata.ownerOf(id);
    }

    function testApproveAll(address to, bool approved) public {
        token__approve.setApprovalForAll(to, approved);

        assertBoolEq(token__metadata.isApprovedForAll(address(this), to), approved);
    }

    function testTransferFrom(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token__mint.mint(from, id);

        hevm.prank(from);
        token__approve.approve(address(this), id);

        token__transfer.transferFrom(from, to, id);

        assertEq(token__metadata.getApproved(id), address(0));
        assertEq(token__metadata.ownerOf(id), to);
        assertEq(token__metadata.balanceOf(to), 1);
        assertEq(token__metadata.balanceOf(from), 0);
    }

    function testTransferFromSelf(uint256 id, address to) public {
        if (to == address(0) || to == address(this)) to = address(0xBEEF);

        token__mint.mint(address(this), id);

        token__transfer.transferFrom(address(this), to, id);

        assertEq(token__metadata.getApproved(id), address(0));
        assertEq(token__metadata.ownerOf(id), to);
        assertEq(token__metadata.balanceOf(to), 1);
        assertEq(token__metadata.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token__mint.mint(from, id);

        hevm.prank(from);
        token__approve.setApprovalForAll(address(this), true);

        token__transfer.transferFrom(from, to, id);

        assertEq(token__metadata.getApproved(id), address(0));
        assertEq(token__metadata.ownerOf(id), to);
        assertEq(token__metadata.balanceOf(to), 1);
        assertEq(token__metadata.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token__mint.mint(from, id);

        hevm.prank(from);
        token__approve.setApprovalForAll(address(this), true);

        token__transfer.safeTransferFrom(from, to, id);

        assertEq(token__metadata.getApproved(id), address(0));
        assertEq(token__metadata.ownerOf(id), to);
        assertEq(token__metadata.balanceOf(to), 1);
        assertEq(token__metadata.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(uint256 id) public {
        address from = address(0xABCD);

        ERC721Recipient recipient = new ERC721Recipient();

        token__mint.mint(from, id);

        hevm.prank(from);
        token__approve.setApprovalForAll(address(this), true);

        token__transfer.safeTransferFrom(from, address(recipient), id);

        assertEq(token__metadata.getApproved(id), address(0));
        assertEq(token__metadata.ownerOf(id), address(recipient));
        assertEq(token__metadata.balanceOf(address(recipient)), 1);
        assertEq(token__metadata.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertBytesEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData(
        uint256 id,
        bytes calldata data
    ) public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token__mint.mint(from, id);

        hevm.prank(from);
        token__approve.setApprovalForAll(address(this), true);

        token__transfer.safeTransferFrom(from, address(recipient), id, data);

        assertEq(token__metadata.getApproved(id), address(0));
        assertEq(token__metadata.ownerOf(id), address(recipient));
        assertEq(token__metadata.balanceOf(address(recipient)), 1);
        assertEq(token__metadata.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertBytesEq(recipient.data(), data);
    }

    function testSafeMintToEOA(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token__mint.safeMint(to, id);

        assertEq(token__metadata.ownerOf(id), address(to));
        assertEq(token__metadata.balanceOf(address(to)), 1);
    }

    function testSafeMintToERC721Recipient(uint256 id) public {
        ERC721Recipient to = new ERC721Recipient();

        token__mint.safeMint(address(to), id);

        assertEq(token__metadata.ownerOf(id), address(to));
        assertEq(token__metadata.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertBytesEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData(
        uint256 id,
        bytes calldata data
    ) public {
        ERC721Recipient to = new ERC721Recipient();

        token__mint.safeMint(address(to), id, data);

        assertEq(token__metadata.ownerOf(id), address(to));
        assertEq(token__metadata.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertBytesEq(to.data(), data);
    }

    function testFailMintToZero(uint256 id) public {
        token__mint.mint(address(0), id);
    }

    function testFailDoubleMint(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token__mint.mint(to, id);
        token__mint.mint(to, id);
    }

    function testFailBurnUnMinted(uint256 id) public {
        token__burn.burn(id);
    }

    function testFailDoubleBurn(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token__mint.mint(to, id);

        token__burn.burn(id);
        token__burn.burn(id);
    }

    function testFailApproveUnMinted(uint256 id, address to) public {
        token__approve.approve(to, id);
    }

    function testFailApproveUnAuthorized(
        address owner,
        uint256 id,
        address to
    ) public {
        if (owner == address(0) || owner == address(this))
            owner = address(0xBEEF);

        token__mint.mint(owner, id);

        token__approve.approve(to, id);
    }

    function testFailTransferFromUnOwned(
        address from,
        address to,
        uint256 id
    ) public {
        token__transfer.transferFrom(from, to, id);
    }

    function testFailTransferFromWrongFrom(
        address owner,
        address from,
        address to,
        uint256 id
    ) public {
        if (owner == address(0)) to = address(0xBEEF);
        if (from == owner) revert();

        token__mint.mint(owner, id);

        token__transfer.transferFrom(from, to, id);
    }

    function testFailTransferFromToZero(uint256 id) public {
        token__mint.mint(address(this), id);

        token__transfer.transferFrom(address(this), address(0), id);
    }

    function testFailTransferFromNotOwner(
        address from,
        address to,
        uint256 id
    ) public {
        if (from == address(this)) from = address(0xBEEF);

        token__mint.mint(from, id);

        token__transfer.transferFrom(from, to, id);
    }

    function testFailSafeTransferFromToNonERC721Recipient(uint256 id) public {
        token__mint.mint(address(this), id);

        token__transfer.safeTransferFrom(
            address(this),
            address(new NonERC721Recipient()),
            id
        );
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData(
        uint256 id,
        bytes calldata data
    ) public {
        token__mint.mint(address(this), id);

        token__transfer.safeTransferFrom(
            address(this),
            address(new NonERC721Recipient()),
            id,
            data
        );
    }

    function testFailSafeTransferFromToRevertingERC721Recipient(uint256 id)
        public
    {
        token__mint.mint(address(this), id);

        token__transfer.safeTransferFrom(
            address(this),
            address(new RevertingERC721Recipient()),
            id
        );
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData(
        uint256 id,
        bytes calldata data
    ) public {
        token__mint.mint(address(this), id);

        token__transfer.safeTransferFrom(
            address(this),
            address(new RevertingERC721Recipient()),
            id,
            data
        );
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData(
        uint256 id
    ) public {
        token__mint.mint(address(this), id);

        token__transfer.safeTransferFrom(
            address(this),
            address(new WrongReturnDataERC721Recipient()),
            id
        );
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData(
        uint256 id,
        bytes calldata data
    ) public {
        token__mint.mint(address(this), id);

        token__transfer.safeTransferFrom(
            address(this),
            address(new WrongReturnDataERC721Recipient()),
            id,
            data
        );
    }

    function testFailSafeMintToNonERC721Recipient(uint256 id) public {
        token__mint.safeMint(address(new NonERC721Recipient()), id);
    }

    function testFailSafeMintToNonERC721RecipientWithData(
        uint256 id,
        bytes calldata data
    ) public {
        token__mint.safeMint(address(new NonERC721Recipient()), id, data);
    }

    function testFailSafeMintToRevertingERC721Recipient(uint256 id) public {
        token__mint.safeMint(address(new RevertingERC721Recipient()), id);
    }

    function testFailSafeMintToRevertingERC721RecipientWithData(
        uint256 id,
        bytes calldata data
    ) public {
        token__mint.safeMint(address(new RevertingERC721Recipient()), id, data);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnData(uint256 id)
        public
    {
        token__mint.safeMint(address(new WrongReturnDataERC721Recipient()), id);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData(
        uint256 id,
        bytes calldata data
    ) public {
        token__mint.safeMint(address(new WrongReturnDataERC721Recipient()), id, data);
    }

    function testFailOwnerOfUnminted(uint256 id) public view {
        token__metadata.ownerOf(id);
    }
}

library Selector {
    function selectors(TransferFacetMock c) public pure returns(bytes4[] memory) {
        bytes4[] memory sigs = new bytes4[](3);
        sigs[0] = bytes4(0x23b872dd);
        sigs[1] = bytes4(0x42842e0e); 
        sigs[2] = bytes4(0xb88d4fde); 
        return sigs;
    } 

    function selectors(MetadataFacet c) public pure returns(bytes4[] memory) {        
        bytes4[] memory sigs = new bytes4[](7);
        sigs[0] = bytes4(0x5b9c7303);
        sigs[1] = bytes4(0x06fdde03); 
        sigs[2] = bytes4(0x95d89b41); 
        sigs[3] = bytes4(0x6352211e);
        sigs[4] = bytes4(0x70a08231); 
        sigs[5] = bytes4(0x081812fc); 
        sigs[6] = bytes4(0xe985e9c5);
        return sigs;
    } 

    function selectors(MintFacetMock c) public pure returns(bytes4[] memory) {
        bytes4[] memory sigs = new bytes4[](3);
        sigs[0] = bytes4(0x40c10f19);
        sigs[1] = bytes4(0xa1448194); 
        sigs[2] = bytes4(0x8832e6e3); 
        return sigs;
    } 

    function selectors(ApproveFacetMock c) public pure returns(bytes4[] memory) {
        bytes4[] memory sigs = new bytes4[](2);
        sigs[0] = bytes4(0x095ea7b3);
        sigs[1] = bytes4(0xa22cb465); 
        return sigs;
    } 

    function selectors(BurnFacetMock c) public pure returns(bytes4[] memory) {
        bytes4[] memory sigs = new bytes4[](1);
        sigs[0] = bytes4(0x42966c68);
        return sigs;
    }

    function selectors(DiamondCutFacet c) public pure returns(bytes4[] memory) {
        bytes4[] memory sigs = new bytes4[](1);
        sigs[0] = bytes4(0xa88efd05);
        return sigs;
    } 

    function selectors(DiamondLoupeFacet c) public pure returns(bytes4[] memory) {
        bytes4[] memory sigs = new bytes4[](5);
        sigs[0] = bytes4(0x7a0ed627);
        sigs[1] = bytes4(0xadfca15e); 
        sigs[2] = bytes4(0x52ef6b2c);
        sigs[3] = bytes4(0xcdffacc6);
        sigs[4] = bytes4(0x01ffc9a7);
        return sigs;
    }
}
