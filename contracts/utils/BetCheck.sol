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
        // Round 1
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
        // Round 2
        for (uint8 i = 8; i < 12; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, EAST).matchesRound2[i % 4]
                )
            );
        }
        // Round 3
        for (uint8 i = 12; i < 14; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, EAST).matchesRound3[i % 2]
                )
            );
        }
        // Round 4
        (points, betResults[14]) = OnchainMadnessLib.calculateResults(
            points,
            bets[14],
            factory.getMatch(year, factory.getRegion(year, EAST).matchRound4)
        );

        // SOUTH
        // Round 1
        for (uint8 i = 15; i < 23; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, SOUTH).matchesRound1[(i-15) % 8]
                )
            );
        }
        // Round 2
        for (uint8 i = 23; i < 27; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, SOUTH).matchesRound2[(i-15) % 4]
                )
            );
        }
        // Round 3
        for (uint8 i = 27; i < 29; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, SOUTH).matchesRound3[(i-15) % 2]
                )
            );
        }
        // Round 4
        (points, betResults[29]) = OnchainMadnessLib.calculateResults(
            points,
            bets[29],
            factory.getMatch(year, factory.getRegion(year, SOUTH).matchRound4)
        );

        // WEST
        // Round 1
        for (uint8 i = 30; i < 38; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, WEST).matchesRound1[(i-30) % 8]
                )
            );
        }
        // Round 2
        for (uint8 i = 38; i < 42; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, WEST).matchesRound2[(i-30) % 4]
                )
            );
        }
        // Round 3
        for (uint8 i = 42; i < 44; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, WEST).matchesRound3[(i-30) % 2]
                )
            );
        }
        // Round 4
        (points, betResults[44]) = OnchainMadnessLib.calculateResults(
            points,
            bets[44],
            factory.getMatch(year, factory.getRegion(year, WEST).matchRound4)
        );

        // MIDWEST
        // Round 1
        for (uint8 i = 45; i < 53; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, MIDWEST).matchesRound1[(i-45) % 8]
                )
            );
        }
        // Round 2
        for (uint8 i = 53; i < 57; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, MIDWEST).matchesRound2[(i-45) % 4]
                )
            );
        }
        // Round 3
        for (uint8 i = 57; i < 59; i++) {
            (points, betResults[i]) = OnchainMadnessLib.calculateResults(
                points,
                bets[i],
                factory.getMatch(
                    year,
                    factory.getRegion(year, MIDWEST).matchesRound3[(i-45) % 2]
                )
            );
        }
        // Round 4
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
