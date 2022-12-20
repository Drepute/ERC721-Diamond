# ERC-721 implementation as a Diamond Proxy

ERC 721 Diamond implementation based on [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535) and inspired from the [reference implementation](https://eips.ethereum.org/EIPS/eip-2535#reference-implementation)

## Facets
- DiamondCutFacet
- DiamondLoupeFacet
- MintFacet
- BurnFacet
- ApproveFacet
- TransferFacet
- MetadataFacet


## Acknowledgements
These contracts were inspired by or directly modified from many sources, primarily:

- [solmate ERC721](https://github.com/transmissions11/solmate)
- [chiru-labs ERC721A-Upgradeable](https://github.com/chiru-labs/ERC721A-Upgradeable)