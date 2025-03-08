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
                        [uint16(5), uint16(32)],
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
                        [uint16(34), uint16(48)],
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
                        8,
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
                        [uint16(12), uint16(36)],
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
                        [uint16(39), uint16(50)],
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
                        16,
                        false,
                        [437, 180, 607, 180, 437, 219, 607, 219, 437, 259]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        [uint16(21), uint16(40)],
                        false,
                        [607, 259, 437, 298, 607, 298, 437, 389, 607, 389]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        [uint16(42), uint16(52)],
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
                        24,
                        false,
                        [437, 609, 607, 609, 437, 648, 607, 648, 437, 688]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        [uint16(29), uint16(44)],
                        false,
                        [607, 688, 437, 727, 607, 727, 437, 818, 607, 818]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        [uint16(46), uint16(54)],
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
