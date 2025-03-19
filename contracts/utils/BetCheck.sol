// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IOnchainMadnessFactory.sol";
import "../libraries/OnchainMadnessBetLib.sol";

contract BetCheck {
    IOnchainMadnessFactory public factory;
    bytes32 public constant EAST = keccak256("EAST");
    bytes32 public constant SOUTH = keccak256("SOUTH");
    bytes32 public constant WEST = keccak256("WEST");
    bytes32 public constant MIDWEST = keccak256("MIDWEST");

    mapping(uint256 => uint8[4]) public yearToRegionPosition;

    modifier onlyAdmin() {
        require(factory.owner() == msg.sender, "Caller is not admin");
        _;
    }

    constructor(address _factory) {
        factory = IOnchainMadnessFactory(_factory);
    }

    function setDeployer(address _factory) public onlyAdmin {
        factory = IOnchainMadnessFactory(_factory);
    }

    function setRegionPosition(
        uint256 year,
        uint8[4] memory position
    ) public onlyAdmin {
        yearToRegionPosition[year] = position;
    }

    function getBetTeamNames(
        uint256 year,
        uint8[63] memory bets
    ) public view returns (string[63] memory teamNames) {
        teamNames = factory.getTeamSymbols(
            year,
            OnchainMadnessBetLib.betTeamIds(
                bets,
                factory.getRegion(year, EAST).teams,
                factory.getRegion(year, SOUTH).teams,
                factory.getRegion(year, WEST).teams,
                factory.getRegion(year, MIDWEST).teams,
                yearToRegionPosition[year]
            )
        );
    }

    function getBetResults(
        uint256 year,
        uint8[63] memory bets
    ) public view returns (uint8[63] memory betResults, uint8 points) {
        uint8[63] memory teamIds = OnchainMadnessBetLib.betTeamIds(
            bets,
            factory.getRegion(year, EAST).teams,
            factory.getRegion(year, SOUTH).teams,
            factory.getRegion(year, WEST).teams,
            factory.getRegion(year, MIDWEST).teams,
            yearToRegionPosition[year]
        );

        (points, betResults) = OnchainMadnessBetLib.calculateResults(
            factory.getFinalResult(year),
            teamIds
        );
    }
}
