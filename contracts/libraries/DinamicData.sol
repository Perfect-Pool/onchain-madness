// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";

library DinamicData {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    function buildBetSquareSmall(
        uint16 x,
        uint16 y,
        uint8 col,
        string memory teamName,
        uint8 status
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    x.toString(),
                    '" y="',
                    y.toString(),
                    '" width="162.5" height="31.5" rx="8" ',
                    (
                        status == 0 ? 'fill="#334155"' : status == 1
                            ? string(
                                abi.encodePacked(
                                    'fill="url(#col',
                                    col.toString(),
                                    '_green)" fill-opacity="0.8"'
                                )
                            )
                            : string(
                                abi.encodePacked(
                                    'fill="url(#col',
                                    col.toString(),
                                    '_red)" fill-opacity="0.8"'
                                )
                            )
                    ),
                    " />",
                    '<text style="font-size:14px;fill:#',
                    (status == 0 ? "94A3B8" : "E2E8F0"),
                    ';font-family:Arial;font-weight:600" text-anchor="middle" x="',
                    (x + 81).toString(),
                    '" y="',
                    (y + 20).toString(),
                    '">',
                    teamName,
                    "</text>"
                )
            );
    }

    function buildBetSquareMedium(
        uint16 x,
        uint16 y,
        uint8 col,
        string memory teamName,
        uint8 status
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    x.toString(),
                    '" y="',
                    y.toString(),
                    '" width="333" height="31.5" rx="8" ',
                    (
                        status == 0 ? 'fill="#334155"' : status == 1
                            ? string(
                                abi.encodePacked(
                                    'fill="url(#col',
                                    col.toString(),
                                    'mid_green)" fill-opacity="0.8"'
                                )
                            )
                            : string(
                                abi.encodePacked(
                                    'fill="url(#col',
                                    col.toString(),
                                    'mid_red)" fill-opacity="0.8"'
                                )
                            )
                    ),
                    " />",
                    '<text style="font-size:14px;fill:#',
                    (status == 0 ? "94A3B8" : "E2E8F0"),
                    ';font-family:Arial;font-weight:600" text-anchor="middle" x="',
                    (x + 166).toString(),
                    '" y="',
                    (y + 23).toString(),
                    '">',
                    teamName,
                    "</text>"
                )
            );
    }

    function buildBetSquareBig(
        uint16 x,
        uint16 y,
        string memory teamName,
        uint8 status
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    x.toString(),
                    '" y="',
                    y.toString(),
                    '" width="690" height="31.5" rx="8" ',
                    (
                        status == 0 ? 'fill="#334155"' : status == 1
                            ? string(
                                abi.encodePacked(
                                    'fill="url(#colbig_green)" fill-opacity="0.8"'
                                )
                            )
                            : string(
                                abi.encodePacked(
                                    'fill="url(#colbig_red)" fill-opacity="0.8"'
                                )
                            )
                    ),
                    " />",
                    '<text style="font-size:14px;fill:#',
                    (status == 0 ? "94A3B8" : "E2E8F0"),
                    ';font-family:Arial;font-weight:600" text-anchor="middle" x="',
                    (x + 345).toString(),
                    '" y="',
                    (y + 21).toString(),
                    '">',
                    teamName,
                    "</text>"
                )
            );
    }

    function nftIdSquare(
        uint256 nftId,
        uint256 poolId,
        string memory poolName,
        string memory prize
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text style="font-size:35px;fill:#86EFAC;font-family:Arial;font-weight:800" x="640" y="74">$',
                    prize,
                    '</text><text style="font-weight:800;font-size:20px;font-family:Arial;fill:#e2e8f0" text-anchor="middle" x="425" y="1298">NFT ID: ',
                    nftId.toString(),
                    " - ",
                    poolName,
                    '</text><text style="font-weight:600;font-size:18px;font-family:Arial;fill:#e2e8f0" text-anchor="middle" x="27" y="660" transform="rotate(270, 27, 660)">perfectpool.io</text>',
                    '<text style="font-weight:600;font-size:18px;font-family:Arial;fill:#e2e8f0" text-anchor="middle" x="823" y="660" transform="rotate(90, 823, 660)">Pool ID: ',
                    poolId.toString(),
                    "</text>"
                )
            );
    }
}
