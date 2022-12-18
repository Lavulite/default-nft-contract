// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./base/OpenSeaFilteredNFT.sol";
import "../../libs/donate/DonateWithdraw.sol";
import "erc721-multi-sales/contracts/multi-wallet/merkletree/ERC721MultiSaleByMerkleMultiWallet.sol";

contract BasicNFTByMarkleForMultiWallets is
    OpenSeaFilteredNFT,
    ERC721MultiSaleByMerkleMultiWallet,
    DonateWithdraw
{
    // ==================================================================
    // Constractor
    // ==================================================================
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 donationRate_
    ) AccessControlledNFT(name_, symbol_) {
        grantRole(ADMIN, msg.sender);
        donationRate = donationRate_;
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
        _setDefaultRoyalty(withdrawAddress, royaltyFee);
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

    function _withdrawAddress() internal override view returns (address payable) {
        return withdrawAddress;
    }

    function setDonationRate(uint256 value) public onlyRole(ADMIN) {
        require(value <= MAX_DONATION_RATE, "donation rate is over 100%");
        donationRate = value;
    }
}
