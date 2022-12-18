// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721AntiScamTimeLock.sol";
import "../../../libs/TokenSupplier/TokenUriSupplier.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract ERC721TokenSupply is ERC721AntiScamTimeLock, TokenUriSupplier {
    using Strings for uint256;

    // ==================================================================
    // override TokenUriSupplier
    // ==================================================================
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Psi, TokenUriSupplier)
        returns (string memory)
    {
        return TokenUriSupplier.tokenURI(tokenId);
    }

    function _defaultTokenUri(uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    tokenId.toString(),
                    isLocked(tokenId) ? "_lock" : "",
                    baseExtension
                )
            );
    }

    function setBaseURI(string memory _value)
        external
        override
        onlyRole(ADMIN)
    {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value)
        external
        override
        onlyRole(ADMIN)
    {
        baseExtension = _value;
    }

    function setExternalSupplier(address _value)
        external
        override
        onlyRole(ADMIN)
    {
        externalSupplier = ITokenUriSupplier(_value);
    }
}
