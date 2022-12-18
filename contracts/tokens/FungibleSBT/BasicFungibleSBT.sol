// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "../../libs/TokenSupplier/TokenUriSupplier.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BasicFungibleSBT is
    ERC1155,
    Ownable,
    AccessControl,
    TokenUriSupplier
{
    using Strings for uint256;

    bytes32 private ADMIN = "ADMIN";
    string private _baseUri;
    string private _baseExtension = ".json";

    constructor() ERC1155("") {
        _grantRole(ADMIN, msg.sender);
    }

    modifier onlyTokenOwner(uint256 id) {
        require(balanceOf(msg.sender, id) > 0, "You don't have the token.");
        _;
    }

    function airdrop(
        address[] calldata to,
        uint256[] calldata amount,
        uint256 id
    ) external onlyRole(ADMIN) {
        require(to.length == amount.length);
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id, amount[i], "");
        }
    }

    function burn(uint256 id) external onlyTokenOwner(id) {
        _burn(msg.sender, id, 1);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId);
    }

    // ==================================================================
    // For SBT
    // ==================================================================
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT, so this can not approve.");
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                from == address(0) || to == address(0),
                "This token is SBT, so this can not transfer."
            );
        }
    }

    // ==================================================================
    // override TokenUriSupplier
    // ==================================================================
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return TokenUriSupplier.tokenURI(tokenId);
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
