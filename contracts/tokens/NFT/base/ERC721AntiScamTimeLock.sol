// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./AccessControlledNFT.sol";

abstract contract ERC721AntiScamTimeLock is AccessControlledNFT {
    // ==================================================================
    // Variables
    // ==================================================================
    // tokenId -> unlock time
    mapping(uint256 => uint256) unlockTokenTimestamp;
    // wallet -> unlock time
    mapping(address => uint256) unlockWalletTimestamp;
    uint256 public unlockLeadTime = 3 hours;

    // ==================================================================
    // Functions
    // ==================================================================
    function setWalletLock(address to, LockStatus lockStatus)
        external
        override
    {
        require(msg.sender == to, "only yourself.");

        if (
            walletLock[to] == LockStatus.Lock && lockStatus != LockStatus.Lock
        ) {
            unlockWalletTimestamp[to] = block.timestamp;
        }

        _setWalletLock(to, lockStatus);
    }

    function _isTokenLockToUnlock(uint256 tokenId, LockStatus newLockStatus)
        private
        view
        returns (bool)
    {
        if (newLockStatus == LockStatus.UnLock) {
            LockStatus currentWalletLock = walletLock[msg.sender];
            bool isWalletLock_TokenLockOrUnset = (currentWalletLock ==
                LockStatus.Lock &&
                tokenLock[tokenId] != LockStatus.UnLock);
            bool isWalletUnlockOrUnset_TokenLock = (currentWalletLock !=
                LockStatus.Lock &&
                tokenLock[tokenId] == LockStatus.Lock);

            return
                isWalletLock_TokenLockOrUnset ||
                isWalletUnlockOrUnset_TokenLock;
        } else if (newLockStatus == LockStatus.UnSet) {
            LockStatus currentWalletLock = walletLock[msg.sender];
            bool isNotWalletLock = currentWalletLock != LockStatus.Lock;
            bool isTokenLock = tokenLock[tokenId] == LockStatus.Lock;

            return isNotWalletLock && isTokenLock;
        } else {
            return false;
        }
    }

    function setTokenLock(uint256[] calldata tokenIds, LockStatus newLockStatus)
        external
        override
    {
        require(tokenIds.length > 0, "tokenIds must be greater than 0.");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(msg.sender == ownerOf(tokenIds[i]), "not owner.");
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_isTokenLockToUnlock(tokenIds[i], newLockStatus)) {
                unlockTokenTimestamp[tokenIds[i]] = block.timestamp;
            }
        }
        _setTokenLock(tokenIds, newLockStatus);
    }

    function _isTokenTimeLock(uint256 tokenId) private view returns (bool) {
        return unlockTokenTimestamp[tokenId] + unlockLeadTime > block.timestamp;
    }

    function _isWalletTimeLock(uint256 tokenId) private view returns (bool) {
        return
            unlockWalletTimestamp[ownerOf(tokenId)] + unlockLeadTime >
            block.timestamp;
    }

    function isLocked(uint256 tokenId)
        public
        view
        override(IERC721Lockable, ERC721Lockable)
        returns (bool)
    {
        return
            ERC721Lockable.isLocked(tokenId) ||
            _isTokenTimeLock(tokenId) ||
            _isWalletTimeLock(tokenId);
    }

    function setUnlockLeadTime(uint256 value) external onlyRole(ADMIN) {
        unlockLeadTime = value;
    }
}
