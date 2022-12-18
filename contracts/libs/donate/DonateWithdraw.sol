// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract DonateWithdraw {
    using Address for address payable;

    address payable public constant donationRecipient =
        payable(0x98ad592418A2Bd5588FeE85734b15905c34e690A);

    uint256 internal constant MAX_DONATION_RATE = 10000;

    // If you would like to donate, please set a number. Thank you. 10% => 1000.
    uint256 public donationRate = 0;

    function _withdraw() internal virtual {
        uint256 donateValue = address(this).balance * donationRate / MAX_DONATION_RATE;
        uint256 withdrawValue = address(this).balance - donateValue;

        _withdrawAddress().sendValue(withdrawValue);
        
        if(donateValue > 0) {
          donationRecipient.sendValue(donateValue);
        }
    }

    function _withdrawAddress() internal virtual returns(address payable); 
}
