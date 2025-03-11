// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IOnchainMadnessFactory.sol";
import "../libraries/OnchainMadnessLib.sol";

contract BetCheck {
    IOnchainMadnessFactory public factory;
    bytes32 public constant EAST = keccak256("EAST");
    bytes32 public constant SOUTH = keccak256("SOUTH");
    bytes32 public constant WEST = keccak256("WEST");
    bytes32 public constant MIDWEST = keccak256("MIDWEST");

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

    function getBetTeamNames(
        uint256 year,
        uint8[63] memory bets
    ) public view returns (string[63] memory teamNames) {
        uint8[16] memory teamsEast = factory.getRegion(year, EAST).teams;
        uint8[16] memory teamsSouth = factory.getRegion(year, SOUTH).teams;
        uint8[16] memory teamsWest = factory.getRegion(year, WEST).teams;
        uint8[16] memory teamsMidwest = factory.getRegion(year, MIDWEST).teams;

        teamNames = factory.getTeamSymbols(
            year,
            OnchainMadnessLib.betTeamIds(
                bets,
                teamsEast,
                teamsSouth,
                teamsWest,
                teamsMidwest
            )
        );
    }

    function getBetResults(
        uint256 year,
        uint8[63] memory bets
    ) public view returns (uint8[63] memory betResults, uint8 points) {
        uint8[16] memory teamsEast = factory.getRegion(year, EAST).teams;
        uint8[16] memory teamsSouth = factory.getRegion(year, SOUTH).teams;
        uint8[16] memory teamsWest = factory.getRegion(year, WEST).teams;
        uint8[16] memory teamsMidwest = factory.getRegion(year, MIDWEST).teams;

        uint8[63] memory teamIds = OnchainMadnessLib.betTeamIds(
            bets,
            teamsEast,
            teamsSouth,
            teamsWest,
            teamsMidwest
        );

        (points, betResults) = OnchainMadnessLib.calculateResults(
            factory.getFinalResult(year),
            teamIds
        );
    }
}
