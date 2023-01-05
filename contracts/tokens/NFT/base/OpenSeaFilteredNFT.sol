// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721TokenSupply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

abstract contract OpenSeaFilteredNFT is
    ERC721TokenSupply,
    ERC2981,
    RevokableDefaultOperatorFilterer
{
    // ==================================================================
    // Variables
    // ==================================================================
    // == For Creator fee ==
    uint96 public royaltyFee = 1000;

    // ==================================================================
    // overrive ERC721Psi for operator-filter-registry
    // ==================================================================
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    // ==================================================================
    // For IERC2981 NFT Royalty Standard
    // ==================================================================
    function setDefaultRoyalty(address payable recipient, uint96 value)
        public
        onlyRole(ADMIN)
    {
        royaltyFee = value;
        _setDefaultRoyalty(recipient, royaltyFee);
    }

    // ==================================================================
    // interface
    // ==================================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlledNFT, ERC2981)
        returns (bool)
    {
        return
            AccessControlledNFT.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
