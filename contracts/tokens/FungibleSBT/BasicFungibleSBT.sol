// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "../../libs/donate/DonateWithdraw.sol";
import "../../libs/TokenSupplier/TokenUriSupplier.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721-multi-sales/contracts/multi-wallet/merkletree/ERC721MultiSaleByMerkleMultiWallet.sol";

// TODO: セールの改善・寄付受付追加
contract BasicFungibleSBT is
    ERC1155,
    Ownable,
    AccessControl,
    DonateWithdraw,
    TokenUriSupplier,
    ERC721MultiSaleByMerkleMultiWallet
{
    using Strings for uint256;

    bytes32 private ADMIN = "ADMIN";
    string private _baseUri;
    string private _baseExtension = ".json";

    constructor(string memory baseUri, address[] memory admins) ERC1155("") {
        _baseUri = baseUri;

        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(ADMIN, admins[i]);
        }
    }

    modifier onlyTokenOwner(uint256 id) {
        require(balanceOf(msg.sender, id) > 0, "You don't have the token.");
        _;
    }

    function mint(address[] calldata to, uint256 id) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id, 1, "");
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

    function setApprovalForAll(address, bool) public virtual override {
        require(false, "This token is SBT, so this can not approve.");
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
    // override ERC721MultiSaleByMerkle
    // ==================================================================
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

    // == For sale ==
    function claim(
        uint256, /*userId*/
        uint248, /*amount*/
        uint248, /*allowedAmount*/
        bytes32[] calldata /*merkleProof*/
    ) external payable {
        revert("Not implemented");
    }

    function claim(
        uint256 userId,
        uint248 amount,
        uint248 allowedAmount,
        uint256 id,
        bytes32[] calldata merkleProof
    )
        external
        payable
        whenNotPaused
        isNotOverAllowedAmount(userId, amount, allowedAmount)
        whenClaimSale
        enoughEth(amount)
        hasRight(userId, amount, allowedAmount, merkleProof)
    {
        _record(userId, amount);
        _mint(msg.sender, id, amount, "");
    }

    function exchange(
        uint256, /*userId*/
        uint256[] calldata, /*burnTokenIds*/
        uint248, /*allowedAmount*/
        bytes32[] calldata /*merkleProof*/
    ) external payable {
        revert("Not implemented");
    }

    function setCurrentSale(Sale calldata sale, bytes32 merkleRoot)
        external
        onlyRole(ADMIN)
    {
        _setCurrentSale(sale);
        _merkleRoot = merkleRoot;
    }

    // ==================================================================
    // override BasicSale
    // ==================================================================
    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    function setWithdrawAddress(address payable value)
        external
        onlyRole(ADMIN)
    {
        withdrawAddress = value;
    }

    function setMaxSupply(uint256 value) external onlyRole(ADMIN) {
        maxSupply = value;
    }

    function _totalSupply() internal pure override returns (uint256) {
        revert("No use.");
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

    // ==================================================================
    // override DonateWithdraw
    // ==================================================================
    function withdraw() external payable override onlyRole(ADMIN) {
        _withdraw();
    }

    function _withdraw() internal override(BasicSale, DonateWithdraw) {
        DonateWithdraw._withdraw();
    }

    function _withdrawAddress()
        internal
        view
        override
        returns (address payable)
    {
        return withdrawAddress;
    }

    function setDonationRate(uint256 value) public onlyRole(ADMIN) {
        require(value <= MAX_DONATION_RATE, "donation rate is over 100%");
        donationRate = value;
    }
}
