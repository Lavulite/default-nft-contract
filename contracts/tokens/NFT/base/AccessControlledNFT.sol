// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721AntiScamQueriable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AccessControlledNFT is
    AccessControl,
    Ownable,
    ERC721AntiScamQueriable
{
    // ==================================================================
    // Constants
    // ==================================================================
    bytes32 public constant ADMIN = "ADMIN";

    // ==================================================================
    // Constractor
    // ==================================================================
    constructor(string memory name_, string memory symbol_)
        ERC721Psi(name_, symbol_)
    {
        grantRole(ADMIN, msg.sender);
    }

    // ==================================================================
    // override ERC721RestrictApprove
    // ==================================================================
    function addLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList()
        external
        view
        returns (address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCAL(address calAddress) external onlyRole(ADMIN) {
        _setCAL(calAddress);
    }

    function setCALLevel(uint256 level) external onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setEnableRestrict(bool value) external onlyRole(ADMIN) {
        enableRestrict = value;
    }

    // ==================================================================
    // override ERC721Loclable
    // ==================================================================
    function setContractLock(LockStatus lockStatus) external onlyRole(ADMIN) {
        _setContractLock(lockStatus);
    }

    function setEnableLock(bool value) external onlyRole(ADMIN) {
        enableLock = value;
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
        override(AccessControl, ERC721AntiScam)
        returns (bool)
    {
        return
            ERC721Psi.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}
