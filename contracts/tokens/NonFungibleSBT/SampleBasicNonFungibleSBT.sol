// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./BasicNonFungibleSBT.sol";

contract SampleBasicNonFungibleSBT is
    BasicNonFungibleSBT
{
    // If you are willing to donate, please set the third argument to a number between 1 (0.01%) and 10000 (100%),
    // and the percentage you set will be donated to the library developer when you withdraw.
    constructor() BasicNonFungibleSBT("SampleSBT", "SSBT", 1000) {}
}
