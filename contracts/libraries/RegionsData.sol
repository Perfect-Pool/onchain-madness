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
                            609,
                            250,
                            609,
                            uint16(80),
                            648,
                            250,
                            648,
                            uint16(80),
                            688
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        20,
                        true,
                        [
                            250,
                            688,
                            uint16(80),
                            727,
                            250,
                            727,
                            uint16(80),
                            818,
                            250,
                            818
                        ]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        25,
                        true,
                        [uint16(80), 857, 250, 857, uint16(80), 948, 250, 948]
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
                        [437, 609, 607, 609, 437, 648, 607, 648, 437, 688]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        50,
                        false,
                        [607, 688, 437, 727, 607, 727, 437, 818, 607, 818]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        55,
                        false,
                        [437, 857, 607, 857, 437, 948, 607, 948]
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
                        [uint16(80), 1029, 250, 1029, 437, 1029, 607, 1029]
                    ),
                    RegionBuilder.finalFour2(
                        betValidator,
                        teams,
                        [uint16(80), 1119, 437, 1119, uint16(80), 1192]
                    )
                )
            );
    }
}
