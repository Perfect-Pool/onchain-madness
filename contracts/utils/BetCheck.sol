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
            OnchainMadnessLib.betTeamNames(
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
        points = 0;

        // EAST
        for (uint8 i = 0; i < 8; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, EAST).matchesRound1[i]
                )
            );
        }

        // SOUTH
        for (uint8 i = 8; i < 16; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, SOUTH).matchesRound1[i % 8]
                )
            );
        }

        //WEST
        for (uint8 i = 16; i < 24; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, WEST).matchesRound1[i % 8]
                )
            );
        }

        //MIDWEST
        for (uint8 i = 24; i < 32; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, MIDWEST).matchesRound1[i % 8]
                )
            );
        }

        //Round 2: four matches, startin from index 32
        // EAST
        for (uint8 i = 32; i < 36; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, EAST).matchesRound2[i % 4]
                )
            );
        }
        //SOUTH
        for (uint8 i = 36; i < 40; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, SOUTH).matchesRound2[i % 4]
                )
            );
        }
        //WEST
        for (uint8 i = 40; i < 44; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, WEST).matchesRound2[i % 4]
                )
            );
        }
        //MIDWEST
        for (uint8 i = 44; i < 48; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, MIDWEST).matchesRound2[i % 4]
                )
            );
        }

        // Round 3: 2 matches, starting from index 48
        //EAST
        for (uint8 i = 48; i < 50; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, EAST).matchesRound3[i % 2]
                )
            );
        }
        //SOUTH
        for (uint8 i = 50; i < 52; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, SOUTH).matchesRound3[i % 2]
                )
            );
        }
        //WEST
        for (uint8 i = 52; i < 54; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, WEST).matchesRound3[i % 2]
                )
            );
        }
        //MIDWEST
        for (uint8 i = 54; i < 56; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, MIDWEST).matchesRound3[i % 2]
                )
            );
        }

        //Round 4
        // EAST
        (points, betResults[56]) = OnchainMadnessLib.calculateResults(
            points,
            bets[56],
            factory.getMatch(year, factory.getRegion(year, EAST).matchRound4)
        );
        //SOUTH
        (points, betResults[57]) = OnchainMadnessLib.calculateResults(
            points,
            bets[57],
            factory.getMatch(year, factory.getRegion(year, SOUTH).matchRound4)
        );
        //WEST
        (points, betResults[58]) = OnchainMadnessLib.calculateResults(
            points,
            bets[58],
            factory.getMatch(year, factory.getRegion(year, WEST).matchRound4)
        );
        //MIDWEST
        (points, betResults[59]) = OnchainMadnessLib.calculateResults(
            points,
            bets[59],
            factory.getMatch(year, factory.getRegion(year, MIDWEST).matchRound4)
        );

        //FINAL FOUR
        (points, betResults[60]) = OnchainMadnessLib.calculateResults(
            points,
            bets[60],
            factory.getMatch(year, factory.getFinalFour(year).matchesRound1[0])
        );
        (points, betResults[61]) = OnchainMadnessLib.calculateResults(
            points,
            bets[61],
            factory.getMatch(year, factory.getFinalFour(year).matchesRound1[1])
        );

        //Final Match
        (points, betResults[62]) = OnchainMadnessLib.calculateResults(
            points,
            bets[62],
            factory.getMatch(year, factory.getFinalFour(year).matchFinal)
        );
    }
}
