// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPerfectPool
 * @dev Interface for interacting with the PerfectPool contract
 */
interface IPerfectPool {
    function increasePool(
        uint256 amountUSDC,
        uint8[] calldata percentage,
        address[] calldata receivers
    ) external;

    function balanceOf(address account) external view returns (uint256);

    function dollarBalance() external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function perfectPrize(uint256 year) external;

    function increaseWinnersQty(uint256 year, address gameContract) external;

    function setAuthorizedMinter(address minter, bool authorized) external;

    function setOnchainMadnessContract(
        address contractAddress,
        bool authorized
    ) external;

    function burnTokens(uint256 amount) external;

    function setLockWithdrawal(bool _lockWithdrawal) external;

    function lockWithdrawal() external view returns (bool);
}