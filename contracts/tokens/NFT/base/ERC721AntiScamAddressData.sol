// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";

abstract contract ERC721AntiScamAddressData is ERC721AntiScam {
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
