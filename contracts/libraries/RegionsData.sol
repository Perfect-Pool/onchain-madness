// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RegionBuilder.sol";

library RegionsData {
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
                        true,
                        [
                            uint16(80),
                            180,
                            250,
                            180,
                            uint16(80),
                            219,
                            250,
                            219,
                            uint16(80),
                            259
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        5,
                        true,
                        [
                            250,
                            259,
                            uint16(80),
                            298,
                            250,
                            298,
                            uint16(80),
                            389,
                            250,
                            389
                        ]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        10,
                        true,
                        [uint16(80), 428, 250, 428, uint16(80), 519, 250, 519]
                    )
                )
            );
    }

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
                        15,
                        true,
                        [
                            uint16(80),
                            701,
                            250,
                            701,
                            uint16(80),
                            740,
                            250,
                            740,
                            uint16(80),
                            780
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        20,
                        true,
                        [
                            250,
                            780,
                            uint16(80),
                            819,
                            250,
                            819,
                            uint16(80),
                            910,
                            250,
                            910
                        ]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        25,
                        true,
                        [uint16(80), 949, 250, 949, uint16(80), 1040, 250, 1040]
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
                        30,
                        false,
                        [437, 180, 607, 180, 437, 219, 607, 219, 437, 259]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        35,
                        false,
                        [607, 259, 437, 298, 607, 298, 437, 389, 607, 389]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        40,
                        false,
                        [437, 428, 607, 428, 437, 519, 607, 519]
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
                        false,
                        [437, 701, 607, 701, 437, 740, 607, 740, 437, 780]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        50,
                        false,
                        [607, 780, 437, 819, 607, 819, 437, 910, 607, 910]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        55,
                        false,
                        [437, 949, 607, 949, 437, 1040, 607, 1040]
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
                        [uint16(80), 609, 437, 609, uint16(80), 1130, 437, 1130]
                    ),
                    RegionBuilder.finalFour2(
                        betValidator,
                        teams,
                        [uint16(80), 1221, 437, 1221, uint16(80), 1294]
                    )
                )
            );
    }
}
