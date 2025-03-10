// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DinamicData.sol";

library RegionBuilder {
    function region1(
        uint8[63] memory betValidator,
        string[63] memory teams,
        uint16 start,
        bool alignLeft,
        uint16[10] memory coords
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DinamicData.buildBetSquareSmall(
                        coords[0],
                        coords[1],
                        alignLeft ? 1 : 3,
                        teams[start],
                        betValidator[start]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[2],
                        coords[3],
                        alignLeft ? 2 : 4,
                        teams[start + 1],
                        betValidator[start + 1]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[4],
                        coords[5],
                        alignLeft ? 1 : 3,
                        teams[start + 2],
                        betValidator[start + 2]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[6],
                        coords[7],
                        alignLeft ? 2 : 4,
                        teams[start + 3],
                        betValidator[start + 3]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[8],
                        coords[9],
                        alignLeft ? 1 : 3,
                        teams[start + 4],
                        betValidator[start + 4]
                    )
                )
            );
    }

    function region2(
        uint8[63] memory betValidator,
        string[63] memory teams,
        uint16 start,
        bool alignLeft,
        uint16[10] memory coords
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DinamicData.buildBetSquareSmall(
                        coords[0],
                        coords[1],
                        alignLeft ? 2 : 4,
                        teams[start],
                        betValidator[start]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[2],
                        coords[3],
                        alignLeft ? 1 : 3,
                        teams[start + 1],
                        betValidator[start + 1]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[4],
                        coords[5],
                        alignLeft ? 2 : 4,
                        teams[start + 2],
                        betValidator[start + 2]
                    ),//fim round 1
                    DinamicData.buildBetSquareSmall(
                        coords[6],
                        coords[7],
                        alignLeft ? 1 : 3,
                        teams[start + 3],
                        betValidator[start + 3]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[8],
                        coords[9],
                        alignLeft ? 2 : 4,
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
        bool alignLeft,
        uint16[8] memory coords
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DinamicData.buildBetSquareSmall(
                        coords[0],
                        coords[1],
                        alignLeft ? 1 : 3,
                        teams[start],
                        betValidator[start]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[2],
                        coords[3],
                        alignLeft ? 2 : 4,
                        teams[start + 1],
                        betValidator[start + 1]
                    ),//fim round 2
                    DinamicData.buildBetSquareSmall(
                        coords[4],
                        coords[5],
                        alignLeft ? 1 : 3,
                        teams[start + 2],
                        betValidator[start + 2]
                    ),
                    DinamicData.buildBetSquareSmall(
                        coords[6],
                        coords[7],
                        alignLeft ? 2 : 4,
                        teams[start + 3],
                        betValidator[start + 3]
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
                    // EAST
                    DinamicData.buildBetSquareSmall(
                        coords[0],
                        coords[1],
                        1,
                        teams[14],
                        betValidator[14]
                    ),
                    // WEST
                    DinamicData.buildBetSquareSmall(
                        coords[2],
                        coords[3],
                        2,
                        teams[44],
                        betValidator[44]
                    ),
                    // SOUTH
                    DinamicData.buildBetSquareSmall(
                        coords[4],
                        coords[5],
                        3,
                        teams[29],
                        betValidator[29]
                    ),
                    // MIDWEST
                    DinamicData.buildBetSquareSmall(
                        coords[6],
                        coords[7],
                        4,
                        teams[59],
                        betValidator[59]
                    )
                )
            );
    }

    function finalFour2(
        uint8[63] memory betValidator,
        string[63] memory teams,
        uint16[6] memory coords
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    DinamicData.buildBetSquareMedium(
                        coords[0],
                        coords[1],
                        1,
                        teams[60],
                        betValidator[60]
                    ),
                    DinamicData.buildBetSquareMedium(
                        coords[2],
                        coords[3],
                        2,
                        teams[61],
                        betValidator[61]
                    ),
                    DinamicData.buildBetSquareBig(
                        coords[4],
                        coords[5],
                        teams[62],
                        betValidator[62]
                    )
                )
            );
    }
}
