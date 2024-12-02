// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RegionBuilder.sol";

library RegionsData {
    function regionSouth(
        uint8[63] memory betValidator,
        string[63] memory teams
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RegionBuilder.region1(
                        betValidator,
                        teams,
                        30,
                        [
                            302,
                            160,
                            302,
                            183,
                            302,
                            206,
                            302,
                            230,
                            405,
                            159,
                            405,
                            183
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        36,
                        [405, 206, 405, 230, 302, 281, 302, 305, 405, 281]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        41,
                        [405, 305, 302, 356, 405, 356]
                    )
                )
            );
    }

    function regionWest(
        uint8[63] memory betValidator,
        string[63] memory teams
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RegionBuilder.region1(
                        betValidator,
                        teams,
                        15,
                        [
                            uint16(38),
                            160,
                            uint16(38),
                            183,
                            uint16(38),
                            206,
                            uint16(38),
                            230,
                            141,
                            160,
                            141,
                            183
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        21,
                        [
                            141,
                            206,
                            141,
                            230,
                            uint16(38),
                            281,
                            uint16(38),
                            305,
                            141,
                            281
                        ]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        26,
                        [141, 305, uint16(38), 356, 141, 356]
                    )
                )
            );
    }

    function regionMidWest(
        uint8[63] memory betValidator,
        string[63] memory teams
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RegionBuilder.region1(
                        betValidator,
                        teams,
                        45,
                        [
                            302,
                            447,
                            302,
                            471,
                            302,
                            494,
                            302,
                            517,
                            405,
                            447,
                            405,
                            471
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        51,
                        [405, 494, 405, 517, 302, 570, 302, 593, 405, 570]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        56,
                        [
                            405,
                            593,
                            302,
                            644,
                            405,
                            644
                        ]
                    )
                )
            );
    }

    function regionEast(
        uint8[63] memory betValidator,
        string[63] memory teams
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RegionBuilder.region1(
                        betValidator,
                        teams,
                        0,
                        [
                            uint16(38),
                            447,
                            uint16(38),
                            471,
                            uint16(38),
                            494,
                            uint16(38),
                            517,
                            141,
                            447,
                            141,
                            471
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        6,
                        [141, 494, 141, 517, uint16(38), 570, uint16(38), 593, 141, 570]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        11,
                        [141, 593, uint16(38), 644, 141, 644]
                    )
                )
            );
    }

    function finalFour(
        uint8[63] memory betValidator,
        string[63] memory teams
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    RegionBuilder.finalFour1(
                        betValidator,
                        teams,
                        [uint16(38), 744, 142, 744, 302, 744, 406, 744]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        60,
                        [172, 802, 274, 802, 222, 826]
                    )
                )
            );
    }
}
