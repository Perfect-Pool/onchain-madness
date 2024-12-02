// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DinamicData.sol";

library RegionBuilder {
    function region1(
        uint8[63] memory betValidator,
        string[63] memory teams,
        uint16 start,
        uint16[12] memory coords
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DinamicData.buildBetSquare(
                        coords[0],
                        coords[1],
                        teams[start],
                        betValidator[start]
                    ),
                    DinamicData.buildBetSquare(
                        coords[2],
                        coords[3],
                        teams[start + 1],
                        betValidator[start + 1]
                    ),
                    DinamicData.buildBetSquare(
                        coords[4],
                        coords[5],
                        teams[start + 2],
                        betValidator[start + 2]
                    ),
                    DinamicData.buildBetSquare(
                        coords[6],
                        coords[7],
                        teams[start + 3],
                        betValidator[start + 3]
                    ),
                    DinamicData.buildBetSquare(
                        coords[8],
                        coords[9],
                        teams[start + 4],
                        betValidator[start + 4]
                    ),
                    DinamicData.buildBetSquare(
                        coords[10],
                        coords[11],
                        teams[start + 5],
                        betValidator[start + 5]
                    )
                )
            );
    }

    function region2(
        uint8[63] memory betValidator,
        string[63] memory teams,
        uint16 start,
        uint16[10] memory coords
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DinamicData.buildBetSquare(
                        coords[0],
                        coords[1],
                        teams[start],
                        betValidator[start]
                    ),
                    DinamicData.buildBetSquare(
                        coords[2],
                        coords[3],
                        teams[start + 1],
                        betValidator[start + 1]
                    ),
                    DinamicData.buildBetSquare(
                        coords[4],
                        coords[5],
                        teams[start + 2],
                        betValidator[start + 2]
                    ),
                    DinamicData.buildBetSquare(
                        coords[6],
                        coords[7],
                        teams[start + 3],
                        betValidator[start + 3]
                    ),
                    DinamicData.buildBetSquare(
                        coords[8],
                        coords[9],
                        teams[start + 4],
                        betValidator[start + 4]
                    )
                )
            );
    }

    function region3(
        uint8[63] memory betValidator,
        string[63] memory teams,
        uint16 start,
        uint16[6] memory coords
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DinamicData.buildBetSquare(
                        coords[0],
                        coords[1],
                        teams[start],
                        betValidator[start]
                    ),
                    DinamicData.buildBetSquare(
                        coords[2],
                        coords[3],
                        teams[start + 1],
                        betValidator[start + 1]
                    ),
                    DinamicData.buildBetSquare(
                        coords[4],
                        coords[5],
                        teams[start + 2],
                        betValidator[start + 2]
                    )
                )
            );
    }

    function finalFour1(
        uint8[63] memory betValidator,
        string[63] memory teams,
        uint16[8] memory coords
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DinamicData.buildBetSquare(
                        coords[0],
                        coords[1],
                        teams[29],
                        betValidator[29]
                    ),
                    DinamicData.buildBetSquare(
                        coords[2],
                        coords[3],
                        teams[14],
                        betValidator[14]
                    ),
                    DinamicData.buildBetSquare(
                        coords[4],
                        coords[5],
                        teams[44],
                        betValidator[44]
                    ),
                    DinamicData.buildBetSquare(
                        coords[6],
                        coords[7],
                        teams[59],
                        betValidator[59]
                    )
                )
            );
    }
}
