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
                            259,
                            250,
                            259
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        6,
                        [
                            uint16(80),
                            298,
                            250,
                            298,
                            uint16(80),
                            389,
                            250,
                            389,
                            uint16(80),
                            428
                        ]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        11,
                        [250, 428, uint16(80), 519, 250, 519]
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
                            437,
                            180,
                            607,
                            180,
                            437,
                            219,
                            607,
                            219,
                            437,
                            259,
                            607,
                            259
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        21,
                        [437, 298, 607, 298, 437, 389, 607, 389, 437, 428]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        26,
                        [607, 428, 437, 519, 607, 519]
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
                        30,
                        [
                            uint16(80),
                            690,
                            250,
                            690,
                            uint16(80),
                            729,
                            250,
                            729,
                            uint16(80),
                            769,
                            250,
                            769
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        36,
                        [
                            uint16(80),
                            808,
                            250,
                            808,
                            uint16(80),
                            899,
                            250,
                            899,
                            uint16(80),
                            938
                        ]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        41,
                        [250, 938, uint16(80), 1029, 250, 1029]
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
                            437,
                            690,
                            607,
                            690,
                            437,
                            729,
                            607,
                            729,
                            437,
                            769,
                            607,
                            769
                        ]
                    ),
                    RegionBuilder.region2(
                        betValidator,
                        teams,
                        51,
                        [437, 808, 607, 808, 437, 899, 607, 899, 437, 938]
                    ),
                    RegionBuilder.region3(
                        betValidator,
                        teams,
                        56,
                        [607, 938, 437, 1029, 607, 1029]
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
                        [uint16(80), 519, 250, 519, 437, 609, 607, 609]
                    ),
                    RegionBuilder.finalFour2(
                        betValidator,
                        teams,
                        60,
                        [uint16(80), 1119, 437, 1119, uint16(80), 1192]
                    )
                )
            );
    }
}
