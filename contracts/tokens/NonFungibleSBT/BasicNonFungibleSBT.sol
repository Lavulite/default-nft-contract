// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "../../libs/TokenSupplier/TokenUriSupplier.sol";
import "../../libs/donate/DonateWithdraw.sol";
import "erc721psi/contracts/extension/ERC721PsiBurnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721-multi-sales/contracts/multi-wallet/merkletree/ERC721MultiSaleByMerkleMultiWallet.sol";

abstract contract BasicNonFungibleSBT is
    AccessControl,
    Ownable,
    ERC721PsiBurnable,
    ERC721MultiSaleByMerkleMultiWallet,
    DonateWithdraw,
    TokenUriSupplier
{
    // ==================================================================
    // Constants
    // ==================================================================
    bytes32 public constant ADMIN = "ADMIN";

    // ==================================================================
    // Constractor
    // ==================================================================
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 donationRate_
    ) ERC721Psi(name_, symbol_) {
        grantRole(ADMIN, msg.sender);
        donationRate = donationRate_;
    }

    // ==================================================================
    // For SBT
    // ==================================================================
    function setApprovalForAll(
        address, /*operator*/
        bool /*approved*/
    ) public virtual override {
        revert("This token is SBT.");
    }

    function approve(
        address, /*to*/
        uint256 /*tokenId*/
    ) public virtual override {
        revert("This token is SBT.");
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256, /*startTokenId*/
        uint256 /*quantity*/
    ) internal virtual override {
        require(
            from == address(0) || to == address(0),
            "This token is SBT, so this can not transfer."
        );
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    // ==================================================================
    // interface
    // ==================================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Psi)
        returns (bool)
    {
        return
            ERC721Psi.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // ==================================================================
    // override ERC721MultiSaleByMerkle
    // ==================================================================
    function airdrop(address[] calldata to, uint256[] calldata amount)
        external
        onlyRole(ADMIN)
    {
        require(to.length == amount.length);
        for (uint256 i = 0; i < to.length; i++) {
            require(
                amount[i] + _totalSupply() <= maxSupply,
                "claim is over the max supply."
            );
            _safeMint(to[i], amount[i]);
        }
    }

    function burn(uint256[] calldata ids) external {
        require(ids.length > 0, "ids is empty.");
        for(uint256 i = 0; i < ids.length; i++){
            require(ownerOf(ids[i]) == msg.sender, "you are not owner.");
            _burn(ids[i]);
        }
    }

    // == For sale ==
    function claim(
        uint256 userId,
        uint248 amount,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable enoughEth(amount) {
        _claim(userId, amount, allowedAmount, merkleProof);
        _safeMint(msg.sender, amount);
    }

    function exchange(
        uint256 userId,
        uint256[] calldata burnTokenIds,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable enoughEth(burnTokenIds.length) {
        _exchange(userId, burnTokenIds, allowedAmount, merkleProof);

        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            _burn(burnTokenIds[i]);
        }

        _safeMint(msg.sender, burnTokenIds.length);
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

    function _totalSupply() internal view override returns (uint256) {
        return totalSupply();
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

    // ==================================================================
    // override TokenUriSupplier
    // ==================================================================
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(TokenUriSupplier, ERC721Psi)
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
    // ERC721PsiAddressData
    // ==================================================================
    // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address _owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            _owner != address(0),
            "ERC721Psi: balance query for the zero address"
        );
        return uint256(_addressData[_owner].balance);
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfersForAddressData(
        address from,
        address to,
        uint256, /*startTokenId*/
        uint256 quantity
    ) internal virtual {
        require(quantity < 2**64);
        uint64 _quantity = uint64(quantity);

        if (from != address(0)) {
            _addressData[from].balance -= _quantity;
        } else {
            // Mint
            _addressData[to].numberMinted += _quantity;
        }

        if (to != address(0)) {
            _addressData[to].balance += _quantity;
        } else {
            // Burn
            _addressData[from].numberBurned += _quantity;
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        _afterTokenTransfersForAddressData(from, to, startTokenId, quantity);
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }
}
