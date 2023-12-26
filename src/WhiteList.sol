// SPDX-License-Identifier:MIT

pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) private whitelistedAddresses;

    constructor() Ownable(msg.sender) {}

    function whitelistAddress(address _addressToWhitelist) external onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function removeAddressFromWhitelist(
        address _addressToRemove
    ) external onlyOwner {
        whitelistedAddresses[_addressToRemove] = false;
    }

    function isAddressWhitelisted(
        address _address
    ) external view returns (bool) {
        return whitelistedAddresses[_address];
    }
}
