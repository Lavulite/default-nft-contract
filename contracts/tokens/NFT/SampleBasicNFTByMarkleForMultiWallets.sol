// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./BasicNFTByMarkleForMultiWallets.sol";

contract SampleBasicNFTByMarkleForMultiWallets is
    BasicNFTByMarkleForMultiWallets
{
    // If you are willing to donate, please set the third argument to a number between 1 (0.01%) and 10000 (100%),
    // and the percentage you set will be donated to the library developer when you withdraw.
    constructor() BasicNFTByMarkleForMultiWallets("SampleNFT", "SNFT", 1000) {}
}
